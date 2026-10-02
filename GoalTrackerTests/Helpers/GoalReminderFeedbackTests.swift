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
				_ = feedback.issue
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
		let issue = try #require(feedback.issue)
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
		await feedback.sync(
			state: GoalReminderSyncState(goal: makeGoal()),
			context: .progressSaved,
			scheduler: scheduler,
			requestsAuthorization: false,
		)
		#expect((feedback.issue != nil) == (outcome == .permissionDenied))
		if let issue = feedback.issue {
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
		await feedback.retry(modelContext: container.mainContext, scheduler: scheduler)

		#expect(!container.mainContext.hasChanges)
		#expect(!feedback.isRetrying)
		if scenario == "disabled" || scenario == "deleted" {
			#expect(scheduler.states.isEmpty)
			#expect(feedback.issue == nil)
		} else if scenario == "disabledDuringRetry" || scenario == "deletedDuringRetry" {
			#expect(scheduler.states.count == 1)
			#expect(scheduler.canceledGoalIds == [goal.id])
			#expect(feedback.issue == nil)
		} else {
			#expect(scheduler.states.count == 1)
			#expect(scheduler.states.first?.goalName == "Updated goal")
			#expect((feedback.issue != nil) == (scenario != "updated"))
			if scenario == "denied" { #expect(feedback.issue?.isPermissionDenied == true) }
			if scenario == "failure" { #expect(feedback.issue?.error is Failure) }
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
				#expect(feedback.issue == nil)
			} catch { Issue.record(error) }
		}

		await feedback.sync(
			state: GoalReminderSyncState(goal: goal),
			context: .progressSaved,
			scheduler: scheduler,
			requestsAuthorization: false,
			modelContext: container.mainContext,
		)
		#expect(feedback.issue == nil)
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
				await feedback.retry(modelContext: container.mainContext, scheduler: scheduler)
			}
		}
		#expect(feedback.isRetrying)
		await feedback.retry(modelContext: container.mainContext, scheduler: scheduler)
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
		release?.resume()
		await retryTask?.value
		#expect(!feedback.isRetrying)
		#expect(feedback.issue?.goalId == otherGoal.id)
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
