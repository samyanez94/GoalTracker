//
//  GoalNotificationSchedulerTests.swift
//  GoalTrackerTests
//
//  Created by Codex on 5/21/26.
//

import Foundation
import Testing
import UserNotifications

@testable import GoalTracker

// MARK: - GoalNotificationSchedulerTests

@MainActor
struct GoalNotificationSchedulerTests {
    @Test
    func `Requesting authorization asks notification center when status is undetermined`() async throws {
        let notificationCenter = FakeNotificationCenter(status: .notDetermined)
        let scheduler = makeScheduler(notificationCenter: notificationCenter)

        let isAuthorized = try await scheduler.requestAuthorizationIfNeeded()

        #expect(isAuthorized)
        #expect(notificationCenter.requestedAuthorizationOptions == [.alert, .sound])
    }

    @Test
    func `Requesting authorization returns false when denied`() async throws {
        let notificationCenter = FakeNotificationCenter(status: .denied)
        let scheduler = makeScheduler(notificationCenter: notificationCenter)

        let isAuthorized = try await scheduler.requestAuthorizationIfNeeded()

        #expect(isAuthorized == false)
        #expect(notificationCenter.requestedAuthorizationOptions == nil)
    }

    @Test
    func `Syncing eligible reminders requests authorization before scheduling`() async throws {
        let notificationCenter = FakeNotificationCenter(status: .notDetermined)
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            dueDate: date(year: 2026, month: 5, day: 21),
            earlyReminder: .daysBeforeDueDate(1),
        )

        let didSchedule = try await scheduler.syncReminder(
            for: goal,
            requestsAuthorization: true,
        )

        #expect(didSchedule)
        #expect(notificationCenter.requestedAuthorizationOptions == [.alert, .sound])
        #expect(notificationCenter.addedRequests.count == 2)
        #expect(notificationCenter.removedIdentifiers == [
            scheduler.dueDateNotificationIdentifier(for: goal.id),
            scheduler.earlyReminderNotificationIdentifier(for: goal.id),
        ])
    }

    @Test
    func `Syncing ineligible reminder cancels without requesting authorization`() async throws {
        let notificationCenter = FakeNotificationCenter(status: .notDetermined)
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            dueDate: nil,
            earlyReminder: .daysBeforeDueDate(1),
        )

        let didSchedule = try await scheduler.syncReminder(
            for: goal,
            requestsAuthorization: true,
        )

        #expect(didSchedule == false)
        #expect(notificationCenter.requestedAuthorizationOptions == nil)
        #expect(notificationCenter.addedRequests.isEmpty)
        #expect(notificationCenter.removedIdentifiers == [
            scheduler.dueDateNotificationIdentifier(for: goal.id),
            scheduler.earlyReminderNotificationIdentifier(for: goal.id),
        ])
    }

    @Test
    func `Syncing denied reminder authorization skips scheduling`() async throws {
        let notificationCenter = FakeNotificationCenter(status: .denied)
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            dueDate: date(year: 2026, month: 5, day: 21),
            earlyReminder: .daysBeforeDueDate(1),
        )

        let didSchedule = try await scheduler.syncReminder(
            for: goal,
            requestsAuthorization: true,
        )

        #expect(didSchedule == false)
        #expect(notificationCenter.addedRequests.isEmpty)
        #expect(notificationCenter.removedIdentifiers == [
            scheduler.dueDateNotificationIdentifier(for: goal.id),
            scheduler.earlyReminderNotificationIdentifier(for: goal.id),
        ])
    }

    @Test
    func `Scheduling due date reminder adds calendar notification request`() async throws {
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            id: goalID,
            dueDate: date(year: 2026, month: 5, day: 21),
        )

        let didSchedule = try await scheduler.scheduleReminder(for: goal)

        let request = try #require(notificationCenter.addedRequests.first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(didSchedule)
        #expect(notificationCenter.addedRequests.count == 1)
        #expect(request.identifier == scheduler.dueDateNotificationIdentifier(for: goalID))
        #expect(request.content.title == "File taxes")
        #expect(request.content.body == "Complete by next month")
        #expect(request.content.sound == .default)
        #expect(trigger.dateComponents.year == 2026)
        #expect(trigger.dateComponents.month == 5)
        #expect(trigger.dateComponents.day == 21)
        #expect(trigger.dateComponents.hour == 9)
        #expect(trigger.dateComponents.minute == 0)
    }

    @Test
    func `Scheduling early reminder adds second notification request`() async throws {
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            id: goalID,
            dueDate: date(year: 2026, month: 5, day: 21),
            earlyReminder: .daysBeforeDueDate(1),
        )

        let didSchedule = try await scheduler.scheduleReminder(for: goal)

        let dueDateRequest = try #require(notificationCenter.addedRequests.first)
        let earlyRequest = try #require(notificationCenter.addedRequests.dropFirst().first)
        let earlyTrigger = try #require(earlyRequest.trigger as? UNCalendarNotificationTrigger)
        #expect(didSchedule)
        #expect(notificationCenter.addedRequests.count == 2)
        #expect(dueDateRequest.identifier == scheduler.dueDateNotificationIdentifier(for: goalID))
        #expect(earlyRequest.identifier == scheduler.earlyReminderNotificationIdentifier(for: goalID))
        #expect(earlyTrigger.dateComponents.year == 2026)
        #expect(earlyTrigger.dateComponents.month == 5)
        #expect(earlyTrigger.dateComponents.day == 20)
        #expect(earlyTrigger.dateComponents.hour == 9)
        #expect(earlyTrigger.dateComponents.minute == 0)
    }

    @Test
    func `Scheduling reminder skips completed goals`() async throws {
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            dueDate: date(year: 2026, month: 5, day: 21),
            earlyReminder: .daysBeforeDueDate(1),
            progress: .outcomeCompleted,
        )

        let didSchedule = try await scheduler.scheduleReminder(for: goal)

        #expect(didSchedule == false)
        #expect(notificationCenter.addedRequests.isEmpty)
        #expect(notificationCenter.removedIdentifiers == [
            scheduler.dueDateNotificationIdentifier(for: goal.id),
            scheduler.earlyReminderNotificationIdentifier(for: goal.id),
        ])
    }

    @Test
    func `Scheduling reminder uses today as body for goals due today`() async throws {
        let notificationCenter = FakeNotificationCenter()
        let scheduler = GoalNotificationScheduler(
            notificationCenter: notificationCenter,
            calendar: Calendar(identifier: .gregorian),
            now: { date(year: 2026, month: 5, day: 21, hour: 8) },
        )
        let goal = makeGoal(
            dueDate: date(year: 2026, month: 5, day: 21),
        )

        let didSchedule = try await scheduler.scheduleReminder(for: goal)

        let request = try #require(notificationCenter.addedRequests.first)
        #expect(didSchedule)
        #expect(request.content.title == "File taxes")
        #expect(request.content.body == "Complete by today")
    }

    @Test
    func `Scheduling reminder skips goals without due date`() async throws {
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(notificationCenter: notificationCenter)

        let missingDueDate = try await scheduler.scheduleReminder(for: makeGoal(
            earlyReminder: .daysBeforeDueDate(1),
        ))
        let missingEarlyReminder = try await scheduler.scheduleReminder(for: makeGoal(
            dueDate: date(year: 2026, month: 5, day: 21),
        ))

        #expect(missingDueDate == false)
        #expect(missingEarlyReminder)
        #expect(notificationCenter.addedRequests.count == 1)
    }

    @Test
    func `Scheduling reminder skips past reminder dates`() async throws {
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            dueDate: date(year: 2025, month: 5, day: 21),
            earlyReminder: .daysBeforeDueDate(1),
        )

        let didSchedule = try await scheduler.scheduleReminder(for: goal)

        #expect(didSchedule == false)
        #expect(notificationCenter.addedRequests.isEmpty)
    }

    @Test
    func `Canceling reminders removes stable notification identifiers`() {
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(notificationCenter: notificationCenter)

        scheduler.cancelReminders(for: [firstID, secondID])

        #expect(notificationCenter.removedIdentifiers == [
            scheduler.dueDateNotificationIdentifier(for: firstID),
            scheduler.earlyReminderNotificationIdentifier(for: firstID),
            scheduler.dueDateNotificationIdentifier(for: secondID),
            scheduler.earlyReminderNotificationIdentifier(for: secondID),
        ])
    }

    private func makeScheduler(
        notificationCenter: FakeNotificationCenter,
    ) -> GoalNotificationScheduler {
        GoalNotificationScheduler(
            notificationCenter: notificationCenter,
            calendar: Calendar(identifier: .gregorian),
            now: { date(year: 2026, month: 4, day: 21) },
        )
    }

    private func makeGoal(
        id: UUID = UUID(),
        dueDate: Date? = nil,
        earlyReminder: GoalReminder? = nil,
        progress: GoalProgress = .outcomePending,
    ) -> Goal {
        Goal(
            id: id,
            name: "File taxes",
            details: nil,
            dueDate: dueDate,
            earlyReminder: earlyReminder,
            createdAt: date(year: 2026, month: 1, day: 1),
            progress: progress,
        )
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
    ) -> Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(year: year, month: month, day: day, hour: hour),
        )!
    }
}

// MARK: - FakeNotificationCenter

@MainActor
private final class FakeNotificationCenter: GoalNotificationCenterClient {
    
    var status: GoalNotificationAuthorizationStatus
    
    var requestAuthorizationResult: Bool
    
    var requestedAuthorizationOptions: UNAuthorizationOptions?
    
    var addedRequests: [UNNotificationRequest] = []
    
    var removedIdentifiers: [String] = []

    init(
        status: GoalNotificationAuthorizationStatus = .authorized,
        requestAuthorizationResult: Bool = true,
    ) {
        self.status = status
        self.requestAuthorizationResult = requestAuthorizationResult
    }

    func authorizationStatus() async -> GoalNotificationAuthorizationStatus {
        status
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestedAuthorizationOptions = options
        return requestAuthorizationResult
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
    }
}
