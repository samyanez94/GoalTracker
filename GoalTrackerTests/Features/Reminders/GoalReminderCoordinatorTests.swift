//
//  GoalReminderCoordinatorTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 10/2/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import Foundation
import Observation
import SwiftData
import Testing

@testable import GoalTracker

@MainActor
struct GoalReminderCoordinatorTests {
	@Test
	func `Scheduling failure reports feedback after the goal is persisted`() async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = makeGoal()
		let scheduler = ReminderSchedulingStub()
		scheduler.error = Failure.scheduling
		let coordinator = GoalReminderCoordinator(modelContext: container.mainContext, scheduler: scheduler)
		let service = GoalService(
			modelContext: container.mainContext,
			reminderUpdates: coordinator,
		)
		// Wait for feedback itself, not merely the start of notification work.
		await withCheckedContinuation { continuation in
			withObservationTracking {
				_ = coordinator.issue(for: goal.id)
			} onChange: {
				continuation.resume()
			}
			do {
				try service.addGoal(goal)
			} catch {
				Issue.record(error)
				continuation.resume()
			}
		}

		let persisted = try #require(container.mainContext.fetch(FetchDescriptor<Goal>()).first)
		let issue = try #require(coordinator.issue(for: goal.id))
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
	) async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let scheduler = ReminderSchedulingStub()
		scheduler.outcome = outcome
		let coordinator = GoalReminderCoordinator(modelContext: container.mainContext, scheduler: scheduler)
		let goal = makeGoal()
		container.mainContext.insert(goal)
		try container.mainContext.save()
		await coordinator.sync(
			state: GoalReminderSyncState(goal: goal),
			context: .progressSaved,
			requestsAuthorization: false,
		)
		#expect((coordinator.issue(for: goal.id) != nil) == (outcome == .permissionDenied))
		if let issue = coordinator.issue(for: goal.id) {
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
		let coordinator = GoalReminderCoordinator(modelContext: container.mainContext, scheduler: scheduler)
		await coordinator.sync(
			state: GoalReminderSyncState(goal: goal),
			context: .goalSaved,
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
		await coordinator.retry(for: goal.id)

		#expect(!container.mainContext.hasChanges)
		#expect(!coordinator.isRetrying(for: goal.id))
		if scenario == "disabled" || scenario == "deleted" {
			#expect(scheduler.states.isEmpty)
			#expect(coordinator.issue(for: goal.id) == nil)
		} else if scenario == "disabledDuringRetry" || scenario == "deletedDuringRetry" {
			#expect(scheduler.states.count == 1)
			#expect(scheduler.canceledGoalIds == [goal.id])
			#expect(coordinator.issue(for: goal.id) == nil)
		} else {
			#expect(scheduler.states.count == 1)
			#expect(scheduler.states.first?.goalName == "Updated goal")
			#expect((coordinator.issue(for: goal.id) != nil) == (scenario != "updated"))
			if scenario == "denied" { #expect(coordinator.issue(for: goal.id)?.isPermissionDenied == true) }
			if scenario == "failure" { #expect(coordinator.issue(for: goal.id)?.error is Failure) }
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
		let coordinator = GoalReminderCoordinator(modelContext: container.mainContext, scheduler: scheduler)
		await coordinator.sync(
			state: GoalReminderSyncState(goal: goal),
			context: .goalSaved,
			requestsAuthorization: true,
		)
		scheduler.error = Failure.scheduling
		scheduler.beforeSync = {
			let service = GoalService(
				modelContext: container.mainContext,
				reminderUpdates: coordinator,
			)
			do {
				if deletesGoal { try service.deleteGoal(goal) } else { try service.disableReminder(goal) }
				#expect(coordinator.issue(for: goal.id) == nil)
			} catch { Issue.record(error) }
		}

		await coordinator.sync(
			state: GoalReminderSyncState(goal: goal),
			context: .progressSaved,
			requestsAuthorization: false,
		)
		#expect(coordinator.issue(for: goal.id) == nil)
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
		let coordinator = GoalReminderCoordinator(modelContext: container.mainContext, scheduler: scheduler)
		await coordinator.sync(
			state: GoalReminderSyncState(goal: goal),
			context: .goalSaved,
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
				await coordinator.retry(for: goal.id)
			}
		}
		#expect(coordinator.isRetrying(for: goal.id))
		await coordinator.retry(for: goal.id)
		#expect(scheduler.states.count == 1)
		let otherGoal = makeGoal()
		container.mainContext.insert(otherGoal)
		try container.mainContext.save()
		scheduler.beforeSync = nil
		scheduler.outcome = .permissionDenied
		await coordinator.sync(
			state: GoalReminderSyncState(goal: otherGoal),
			context: .goalSaved,
			requestsAuthorization: true,
		)
		#expect(coordinator.issues.count == 2)
		#expect(!coordinator.isRetrying(for: otherGoal.id))
		scheduler.outcome = .scheduled
		release?.resume()
		await retryTask?.value
		#expect(!coordinator.isRetrying(for: goal.id))
		#expect(coordinator.issue(for: goal.id) == nil)
		#expect(coordinator.issue(for: otherGoal.id)?.goalId == otherGoal.id)
	}

	@Test
	func `Saving retrying and reconciling share the injected scheduler`() async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let center = PermissionNotificationCenterStub(status: .authorized)
		let scheduler = ReminderSchedulingStub()
		scheduler.error = Failure.scheduling
		let coordinator = GoalReminderCoordinator(
			modelContext: container.mainContext,
			notificationCenter: center,
			scheduler: scheduler
		)
		let service = GoalService(modelContext: container.mainContext, reminderUpdates: coordinator)
		let goal = makeGoal()
		await withCheckedContinuation { continuation in
			withObservationTracking {
				_ = coordinator.issue(for: goal.id)
			} onChange: {
				continuation.resume()
			}
			do { try service.addGoal(goal) } catch {
				Issue.record(error)
				continuation.resume()
			}
		}
		scheduler.error = nil
		await coordinator.retry(for: goal.id)
		await coordinator.reconcileReminders()

		#expect(scheduler.states.map(\.goalId) == [goal.id, goal.id, goal.id])
		#expect(scheduler.authorizationRequests == [true, true, false])
		#expect(coordinator.issue(for: goal.id) == nil)
		#expect(center.addedRequestCount == 0)
		try service.disableReminder(goal)
		#expect(scheduler.canceledGoalIds.contains(goal.id))
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
