import Foundation
import Observation
import SwiftData
import Testing

@testable import GoalTracker

@MainActor
struct GoalReminderFeedbackTests {
	@Test
	func `Scheduling failure reports feedback after the goal is persisted`() async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = makeGoal()
		let scheduler = ReminderSchedulingStub()
		scheduler.error = Failure.scheduling
		let feedback = GoalReminderFeedback()
		let manager = GoalManager(
			modelContext: container.mainContext,
			notificationScheduler: scheduler,
			reminderFeedback: feedback,
		)
		// Wait for feedback itself, not merely the start of notification work.
		await withCheckedContinuation { continuation in
			withObservationTracking {
				_ = feedback.issue(for: goal.id)
			} onChange: {
				continuation.resume()
			}
			do {
				try manager.addGoal(goal)
			} catch {
				Issue.record(error)
				continuation.resume()
			}
		}

		let persisted = try #require(container.mainContext.fetch(FetchDescriptor<Goal>()).first)
		let issue = try #require(feedback.issue(for: goal.id))
		#expect(persisted.id == goal.id)
		#expect(persisted.reminder != nil)
		#expect(issue.goalId == goal.id)
		#expect(issue.error is Failure)
		#expect(!issue.isPermissionDenied)
	}

	@Test(arguments: [
		GoalReminderSchedulingOutcome.scheduled, .notNeeded, .permissionDenied
	])
	func `Only denied permission needs feedback for nonthrowing outcomes`(
		outcome: GoalReminderSchedulingOutcome,
	) async {
		let scheduler = ReminderSchedulingStub()
		scheduler.outcome = outcome
		let feedback = GoalReminderFeedback()
		let goal = makeGoal()
		await feedback.sync(
			state: GoalReminderSyncState(goal: goal),
			context: .progressSaved,
			scheduler: scheduler,
			requestsAuthorization: false,
		)
		#expect((feedback.issue(for: goal.id) != nil) == (outcome == .permissionDenied))
		if let issue = feedback.issue(for: goal.id) {
			#expect(issue.isPermissionDenied)
			#expect(issue.message == .reminderFeedbackProgressSavedPermission)
		}
	}

	@Test(arguments: ["updated", "disabled", "deleted", "failure", "denied", "disabledDuringRetry", "deletedDuringRetry"])
	func `Retry uses saved state without rewriting the goal`(scenario: String) async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = makeGoal()
		container.mainContext.insert(goal)
		try container.mainContext.save()
		let scheduler = ReminderSchedulingStub()
		scheduler.error = Failure.scheduling
		let feedback = GoalReminderFeedback()
		await feedback.sync(
			state: GoalReminderSyncState(goal: goal),
			context: .goalSaved,
			scheduler: scheduler,
			requestsAuthorization: true,
		)
		scheduler.states.removeAll()
		scheduler.error = scenario == "failure" ? Failure.scheduling : nil
		scheduler.outcome = scenario == "denied" ? .permissionDenied : .scheduled
		goal.name = "Updated goal"
		if scenario == "disabled" { goal.reminder = nil }
		if scenario == "deleted" { container.mainContext.delete(goal) }
		try container.mainContext.save()

		if scenario == "disabledDuringRetry" || scenario == "deletedDuringRetry" {
			scheduler.beforeSync = {
				if scenario == "disabledDuringRetry" { goal.reminder = nil }
				if scenario == "deletedDuringRetry" { container.mainContext.delete(goal) }
				do { try container.mainContext.save() } catch { Issue.record(error) }
			}
		}
		await feedback.retry(for: goal.id, modelContext: container.mainContext, scheduler: scheduler)

		#expect(!container.mainContext.hasChanges)
		#expect(!feedback.isRetrying(for: goal.id))
		if scenario == "disabled" || scenario == "deleted" {
			#expect(scheduler.states.isEmpty)
			#expect(feedback.issue(for: goal.id) == nil)
		} else if scenario == "disabledDuringRetry" || scenario == "deletedDuringRetry" {
			#expect(scheduler.states.count == 1)
			#expect(scheduler.canceledGoalIds == [goal.id])
			#expect(feedback.issue(for: goal.id) == nil)
		} else {
			#expect(scheduler.states.count == 1)
			#expect(scheduler.states.first?.goalName == "Updated goal")
			#expect((feedback.issue(for: goal.id) != nil) == (scenario != "updated"))
			if scenario == "denied" { #expect(feedback.issue(for: goal.id)?.isPermissionDenied == true) }
			if scenario == "failure" { #expect(feedback.issue(for: goal.id)?.error is Failure) }
		}
	}

	@Test(arguments: [false, true])
	func `Post-save scheduling does not restore an issue after disabling or deleting a goal`(
		deletesGoal: Bool,
	) async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = makeGoal()
		container.mainContext.insert(goal)
		try container.mainContext.save()
		let scheduler = ReminderSchedulingStub()
		scheduler.outcome = .permissionDenied
		let feedback = GoalReminderFeedback()
		await feedback.sync(
			state: GoalReminderSyncState(goal: goal),
			context: .goalSaved,
			scheduler: scheduler,
			requestsAuthorization: true,
		)
		scheduler.error = Failure.scheduling
		scheduler.beforeSync = {
			let manager = GoalManager(
				modelContext: container.mainContext,
				notificationScheduler: scheduler,
				reminderFeedback: feedback,
			)
			do {
				if deletesGoal { try manager.deleteGoal(goal) } else { try manager.disableReminder(goal) }
				#expect(feedback.issue(for: goal.id) == nil)
			} catch { Issue.record(error) }
		}

		await feedback.sync(
			state: GoalReminderSyncState(goal: goal),
			context: .progressSaved,
			scheduler: scheduler,
			requestsAuthorization: false,
			modelContext: container.mainContext,
		)
		#expect(feedback.issue(for: goal.id) == nil)
		#expect(scheduler.canceledGoalIds == [goal.id, goal.id])
	}

	@Test
	func `Suspended retry prevents duplicates and preserves newer feedback`() async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = makeGoal()
		container.mainContext.insert(goal)
		try container.mainContext.save()
		let scheduler = ReminderSchedulingStub()
		scheduler.error = Failure.scheduling
		let feedback = GoalReminderFeedback()
		await feedback.sync(
			state: GoalReminderSyncState(goal: goal),
			context: .goalSaved,
			scheduler: scheduler,
			requestsAuthorization: true,
		)
		scheduler.error = nil
		scheduler.states.removeAll()
		var release: CheckedContinuation<Void, Never>?
		var retryTask: Task<Void, Never>?
		await withCheckedContinuation { started in
			scheduler.beforeSync = {
				await withCheckedContinuation { suspended in
					release = suspended
					started.resume()
				}
			}
			retryTask = Task {
				await feedback.retry(for: goal.id, modelContext: container.mainContext, scheduler: scheduler)
			}
		}
		#expect(feedback.isRetrying(for: goal.id))
		await feedback.retry(for: goal.id, modelContext: container.mainContext, scheduler: scheduler)
		#expect(scheduler.states.count == 1)
		let otherGoal = makeGoal()
		let deniedScheduler = ReminderSchedulingStub()
		deniedScheduler.outcome = .permissionDenied
		await feedback.sync(
			state: GoalReminderSyncState(goal: otherGoal),
			context: .goalSaved,
			scheduler: deniedScheduler,
			requestsAuthorization: true,
		)
		#expect(feedback.issues.count == 2)
		#expect(!feedback.isRetrying(for: otherGoal.id))
		release?.resume()
		await retryTask?.value
		#expect(!feedback.isRetrying(for: goal.id))
		#expect(feedback.issue(for: goal.id) == nil)
		#expect(feedback.issue(for: otherGoal.id)?.goalId == otherGoal.id)
	}

	private func makeGoal() -> Goal {
		Goal(
			name: "Daily walk",
			reminder: GoalReminder(),
			progress: .outcome(OutcomeProgress()),
			recurrence: GoalRecurrence(cadence: .daily),
		)
	}

	private enum Failure: Error {
		case scheduling
	}
}
