import Foundation
import SwiftData
import Testing
import UserNotifications

@testable import GoalTracker

@MainActor
struct GoalReminderReconciliationTests {
	@Test(arguments: ["name", "cadence", "date"])
	func `Reconciliation repairs missing and outdated requests and leaves matching requests untouched`(change: String) async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = makeGoal()
		if change == "date" {
			goal.recurrence = nil
			goal.targetDate = now.addingTimeInterval(86_400)
		}
		container.mainContext.insert(goal)
		try container.mainContext.save()
		let center = PermissionNotificationCenterStub(status: .authorized)
		let coordinator = try makeCoordinator()
		defer { UserDefaults.standard.removePersistentDomain(forName: defaultsSuiteName) }

		await reconcile(coordinator, container: container, center: center)
		#expect(center.addedRequestCount == 1)
		await reconcile(coordinator, container: container, center: center)
		#expect(center.addedRequestCount == 1)

		switch change {
		case "name": goal.name = "Updated goal"
		case "cadence": goal.recurrence = GoalRecurrence(cadence: .weekly)
		default: goal.targetDate = now.addingTimeInterval(172_800)
		}
		try container.mainContext.save()
		await reconcile(coordinator, container: container, center: center)
		#expect(center.addedRequestCount == 2)
		let updated = try #require(center.pendingRequests.first)
		#expect(updated.content.title == goal.name)
		if change == "cadence" {
			#expect((updated.trigger as? UNCalendarNotificationTrigger)?.dateComponents.weekday != nil)
		}
		let scheduler = GoalNotificationScheduler(notificationCenter: center, now: { now })
		#expect(scheduler.isReminderCurrent(for: GoalReminderSyncState(goal: goal), request: updated))
		#expect(center.pendingRequests.count == 1)
		#expect(center.authorizationRequestCount == 0)
		#expect(coordinator.issues.isEmpty)
	}

	@Test(arguments: ["disabled", "completed", "expired", "deleted"])
	func `Reconciliation removes obsolete goal requests and preserves unrelated notifications`(change: String) async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = makeGoal()
		goal.recurrence = nil
		goal.targetDate = now.addingTimeInterval(86_400)
		container.mainContext.insert(goal)
		try container.mainContext.save()
		let center = PermissionNotificationCenterStub(status: .authorized)
		let coordinator = try makeCoordinator()
		defer { UserDefaults.standard.removePersistentDomain(forName: defaultsSuiteName) }
		await reconcile(coordinator, container: container, center: center)
		let identifier = try #require(center.pendingRequests.first?.identifier)
		center.pendingRequests.append(UNNotificationRequest(identifier: "unrelated", content: UNMutableNotificationContent(), trigger: nil))

		switch change {
		case "disabled": goal.reminder = nil
		case "completed": goal.progress = .outcome(OutcomeProgress.completed(timestamp: now))
		case "expired": goal.targetDate = now.addingTimeInterval(-86_400)
		default: container.mainContext.delete(goal)
		}
		try container.mainContext.save()
		await reconcile(coordinator, container: container, center: center)
		#expect(center.removedIdentifiers.contains(identifier))
		#expect(center.pendingRequests.map(\.identifier) == ["unrelated"])
		#expect(center.addedRequestCount == 1)
	}

	@Test(arguments: [GoalNotificationAuthorizationStatus.denied, .notDetermined])
	func `Reconciliation never prompts or schedules when permission is unavailable`(status: GoalNotificationAuthorizationStatus) async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = makeGoal()
		container.mainContext.insert(goal)
		try container.mainContext.save()
		let center = PermissionNotificationCenterStub(status: .authorized)
		let coordinator = try makeCoordinator()
		defer { UserDefaults.standard.removePersistentDomain(forName: defaultsSuiteName) }
		await reconcile(coordinator, container: container, center: center)
		center.status = status
		await reconcile(coordinator, container: container, center: center)
		#expect(center.pendingRequests.isEmpty)
		#expect(center.addedRequestCount == 1)
		#expect(center.authorizationRequestCount == 0)
		#expect((coordinator.issue(for: goal.id) != nil) == (status == .denied))
		center.status = .authorized
		await reconcile(coordinator, container: container, center: center)
		#expect(center.pendingRequests.count == 1)
		#expect(center.addedRequestCount == 2)
		#expect(center.authorizationRequestCount == 0)
		#expect(coordinator.issues.isEmpty)
	}

	@Test
	func `Reconciliation surfaces a scheduling failure and recovers on the next pass`() async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = makeGoal()
		container.mainContext.insert(goal)
		try container.mainContext.save()
		let center = PermissionNotificationCenterStub(status: .authorized)
		let coordinator = try makeCoordinator()
		defer { UserDefaults.standard.removePersistentDomain(forName: defaultsSuiteName) }
		center.addError = Failure.scheduling
		await reconcile(coordinator, container: container, center: center)
		#expect(coordinator.issue(for: goal.id)?.error is Failure)
		#expect(coordinator.issue(for: goal.id)?.message == .reminderFeedbackSchedulingFailure)
		center.addError = nil
		await reconcile(coordinator, container: container, center: center)
		#expect(coordinator.issue(for: goal.id) == nil)
		#expect(center.pendingRequests.count == 1)
	}

	@Test
	func `Reconciliation reads goals after pending requests arrive`() async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = makeGoal()
		let center = PermissionNotificationCenterStub(status: .authorized)
		center.beforePendingRequests = {
			container.mainContext.insert(goal)
		}
		let coordinator = try makeCoordinator()
		defer { UserDefaults.standard.removePersistentDomain(forName: defaultsSuiteName) }
		await reconcile(coordinator, container: container, center: center)
		#expect(center.pendingRequests.first?.content.title == goal.name)
	}

	@Test
	func `Goal changes during another reminder repair use the latest saved state`() async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		container.mainContext.insert(makeGoal())
		container.mainContext.insert(makeGoal())
		try container.mainContext.save()
		let center = PermissionNotificationCenterStub(status: .authorized)
		let coordinator = try makeCoordinator()
		defer { UserDefaults.standard.removePersistentDomain(forName: defaultsSuiteName) }
		await reconcile(coordinator, container: container, center: center)
		let goals = try container.mainContext.fetch(FetchDescriptor<Goal>())
		let first = try #require(goals.first)
		let second = try #require(goals.last)
		first.name = "First update"
		try container.mainContext.save()
		center.beforeAdd = {
			center.beforeAdd = nil
			second.name = "Synced update"
			do { try container.mainContext.save() } catch { Issue.record(error) }
		}
		await reconcile(coordinator, container: container, center: center)
		let scheduler = GoalNotificationScheduler(notificationCenter: center, now: { now })
		let request = center.pendingRequests.first { $0.identifier == scheduler.reminderNotificationIdentifier(for: second.id) }
		#expect(request?.content.title == "Synced update")
		#expect(center.addedRequestCount == 4)
	}

	@Test(arguments: [false, true])
	func `Overlapping reconciliations cannot let an older request overwrite the latest goal`(cancelsOlderPass: Bool) async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = makeGoal()
		container.mainContext.insert(goal)
		try container.mainContext.save()
		let center = PermissionNotificationCenterStub(status: .authorized)
		let coordinator = try makeCoordinator()
		defer { UserDefaults.standard.removePersistentDomain(forName: defaultsSuiteName) }
		let (started, start) = AsyncStream<Void>.makeStream()
		let (resume, continuation) = AsyncStream<Void>.makeStream()
		let (checked, check) = AsyncStream<Void>.makeStream()
		center.beforeAdd = {
			center.beforeAdd = nil
			start.yield(())
			for await _ in resume { break }
		}
		let first = Task { await reconcile(coordinator, container: container, center: center) }
		for await _ in started { break }
		goal.name = "Latest goal"
		try container.mainContext.save()
		center.beforePendingRequests = { check.yield(()) }
		let second = Task { await reconcile(coordinator, container: container, center: center) }
		for await _ in checked { break }
		if cancelsOlderPass { first.cancel() }
		continuation.yield(())
		await first.value
		await second.value
		#expect(center.pendingRequests.count == 1)
		#expect(center.pendingRequests.first?.content.title == "Latest goal")
		#expect(center.addedRequestCount == 2)
	}

	@Test
	func `Permission changes during the pending request fetch use the latest status`() async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		container.mainContext.insert(makeGoal())
		try container.mainContext.save()
		let center = PermissionNotificationCenterStub(status: .denied)
		let coordinator = try makeCoordinator()
		defer { UserDefaults.standard.removePersistentDomain(forName: defaultsSuiteName) }
		center.beforePendingRequests = { center.status = .authorized }
		await reconcile(coordinator, container: container, center: center)
		#expect(center.pendingRequests.count == 1)
		#expect(coordinator.issues.isEmpty)
		#expect(center.authorizationRequestCount == 0)
	}

	@Test
	func `A canceled reconciliation does not schedule or publish feedback`() async throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		container.mainContext.insert(makeGoal())
		try container.mainContext.save()
		let center = PermissionNotificationCenterStub(status: .authorized)
		let coordinator = try makeCoordinator()
		defer { UserDefaults.standard.removePersistentDomain(forName: defaultsSuiteName) }
		center.beforePendingRequests = {
			withUnsafeCurrentTask { $0?.cancel() }
		}
		await Task { await reconcile(coordinator, container: container, center: center) }.value
		#expect(center.pendingRequests.isEmpty)
		#expect(coordinator.issues.isEmpty)
	}

	private let defaultsSuiteName = "GoalReminderReconciliationTests.\(UUID().uuidString)"

	private func makeCoordinator() throws -> GoalReminderCoordinator {
		GoalReminderCoordinator(permissionDefaults: try #require(UserDefaults(suiteName: defaultsSuiteName)))
	}

	private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

	private func makeGoal() -> Goal {
		Goal(name: "Walk", reminder: GoalReminder(), progress: .outcome(OutcomeProgress()), recurrence: GoalRecurrence(cadence: .daily))
	}

	private func reconcile(_ coordinator: GoalReminderCoordinator, container: ModelContainer, center: PermissionNotificationCenterStub) async {
		await coordinator.reconcileReminders(modelContext: container.mainContext, notificationCenter: center, now: { now })
	}

	private enum Failure: Error { case scheduling }
}
