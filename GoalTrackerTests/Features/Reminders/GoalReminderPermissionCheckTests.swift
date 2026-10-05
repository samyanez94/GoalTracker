import Foundation
import SwiftData
import Testing

@testable import GoalTracker

@MainActor
struct GoalReminderPermissionCheckTests {
	@Test(arguments: [false, true])
	func `Denied permission flags every eligible goal and prunes disabled or deleted goals`(
		deletesGoal: Bool,
	) async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let first = makeGoal(name: "Daily walk")
		let second = makeGoal(name: "Read", targetDate: now.addingTimeInterval(86_400))
		let completed = makeGoal(name: "Finished", targetDate: now.addingTimeInterval(86_400))
		completed.progress = .outcome(OutcomeProgress.completed(timestamp: now))
		let expired = makeGoal(name: "Expired", targetDate: now.addingTimeInterval(-86_400))
		let disabled = makeGoal(name: "Disabled")
		disabled.reminder = nil
		for goal in [first, second, completed, expired, disabled] { container.mainContext.insert(goal) }
		try container.mainContext.save()
		let defaults = try makeDefaults()
		defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
		let coordinator = GoalReminderCoordinator(permissionDefaults: defaults)
		let notificationCenter = PermissionNotificationCenterStub(status: .denied)
		let scheduler = ReminderSchedulingStub()

		await coordinator.refreshPermissions(
			modelContext: container.mainContext,
			notificationCenter: notificationCenter,
			scheduler: scheduler,
			now: { now },
		)

		#expect(Set(coordinator.issues.keys) == [first.id, second.id])
		let allPermissionDenied = coordinator.issues.values.allSatisfy(\.isPermissionDenied)
		#expect(allPermissionDenied)
		#expect(coordinator.issue(for: first.id)?.message == .reminderFeedbackPermissionRequired)
		#expect(defaults.bool(forKey: AppStorageKey.wereGoalRemindersDenied))
		#expect(notificationCenter.authorizationRequestCount == 0)
		#expect(notificationCenter.addedRequestCount == 0)
		#expect(scheduler.states.isEmpty)

		let firstId = first.id
		if deletesGoal { container.mainContext.delete(first) } else { first.reminder = nil }
		try container.mainContext.save()
		await coordinator.refreshPermissions(
			modelContext: container.mainContext,
			notificationCenter: notificationCenter,
			scheduler: scheduler,
			now: { now },
		)
		#expect(coordinator.issue(for: firstId) == nil)
		#expect(coordinator.issue(for: second.id)?.isPermissionDenied == true)
		#expect(scheduler.canceledGoalIds == [firstId])
	}

	@Test(arguments: [false, true])
	func `Restored permission retries affected goals without prompting including after relaunch`(
		relaunches: Bool,
	) async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let first = makeGoal(name: "Daily walk")
		let second = makeGoal(name: "Read")
		container.mainContext.insert(first)
		container.mainContext.insert(second)
		try container.mainContext.save()
		let defaults = try makeDefaults()
		defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
		var coordinator = GoalReminderCoordinator(permissionDefaults: defaults)
		let notificationCenter = PermissionNotificationCenterStub(status: .denied)
		let scheduler = ReminderSchedulingStub()
		await coordinator.refreshPermissions(
			modelContext: container.mainContext,
			notificationCenter: notificationCenter,
			scheduler: scheduler,
			now: { now },
		)
		if relaunches { coordinator = GoalReminderCoordinator(permissionDefaults: defaults) }
		notificationCenter.status = .authorized
		scheduler.error = Failure.scheduling
		scheduler.failingGoalIds = [second.id]

		await coordinator.refreshPermissions(
			modelContext: container.mainContext,
			notificationCenter: notificationCenter,
			scheduler: scheduler,
			now: { now },
		)

		#expect(Set(scheduler.states.map(\.goalId)) == [first.id, second.id])
		#expect(scheduler.authorizationRequests == [false, false])
		#expect(notificationCenter.authorizationRequestCount == 0)
		#expect(coordinator.issue(for: first.id) == nil)
		#expect(coordinator.issue(for: second.id)?.error is Failure)
		#expect(coordinator.issue(for: second.id)?.message == .reminderFeedbackSchedulingFailure)
		#expect(!defaults.bool(forKey: AppStorageKey.wereGoalRemindersDenied))
		// Ordinary foreground checks do not continually retry scheduling errors.
		await coordinator.refreshPermissions(
			modelContext: container.mainContext,
			notificationCenter: notificationCenter,
			scheduler: scheduler,
			now: { now },
		)
		#expect(scheduler.states.count == 2)
		#expect(coordinator.issue(for: second.id)?.error is Failure)
	}

	@Test(arguments: [GoalNotificationAuthorizationStatus.notDetermined, .authorized])
	func `A normal launch does not prompt or schedule reminders`(
		status: GoalNotificationAuthorizationStatus,
	) async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		container.mainContext.insert(makeGoal(name: "Daily walk"))
		try container.mainContext.save()
		let defaults = try makeDefaults()
		defer { defaults.removePersistentDomain(forName: defaultsSuiteName) }
		let coordinator = GoalReminderCoordinator(permissionDefaults: defaults)
		let notificationCenter = PermissionNotificationCenterStub(status: status)
		let scheduler = ReminderSchedulingStub()
		await coordinator.refreshPermissions(
			modelContext: container.mainContext,
			notificationCenter: notificationCenter,
			scheduler: scheduler,
			now: { now },
		)
		#expect(coordinator.issues.isEmpty)
		#expect(notificationCenter.authorizationRequestCount == 0)
		#expect(notificationCenter.addedRequestCount == 0)
		#expect(scheduler.states.isEmpty)
	}

	private let defaultsSuiteName = "GoalReminderPermissionCheckTests.\(UUID().uuidString)"

	private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

	private func makeGoal(name: String, targetDate: Date? = nil) -> Goal {
		Goal(
			name: name,
			targetDate: targetDate,
			reminder: GoalReminder(),
			progress: .outcome(OutcomeProgress()),
			recurrence: targetDate == nil ? GoalRecurrence(cadence: .daily) : nil,
		)
	}

	private func makeDefaults() throws -> UserDefaults {
		let defaults = try #require(UserDefaults(suiteName: defaultsSuiteName))
		return defaults
	}

	private enum Failure: Error { case scheduling }
}
