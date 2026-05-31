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
            reminder: GoalReminder(),
        )

        let didSchedule = try await scheduler.syncReminder(
            for: goal,
            requestsAuthorization: true,
        )

        #expect(didSchedule)
        #expect(notificationCenter.requestedAuthorizationOptions == [.alert, .sound])
        #expect(notificationCenter.addedRequests.count == 1)
        #expect(notificationCenter.removedIdentifiers == [
            scheduler.reminderNotificationIdentifier(for: goal.id),
        ])
    }

    @Test
    func `Syncing ineligible reminder cancels without requesting authorization`() async throws {
        let notificationCenter = FakeNotificationCenter(status: .notDetermined)
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            dueDate: nil,
            reminder: GoalReminder(),
        )

        let didSchedule = try await scheduler.syncReminder(
            for: goal,
            requestsAuthorization: true,
        )

        #expect(didSchedule == false)
        #expect(notificationCenter.requestedAuthorizationOptions == nil)
        #expect(notificationCenter.addedRequests.isEmpty)
        #expect(notificationCenter.removedIdentifiers == [
            scheduler.reminderNotificationIdentifier(for: goal.id),
        ])
    }

    @Test
    func `Syncing due date without reminder cancels without requesting authorization`() async throws {
        let notificationCenter = FakeNotificationCenter(status: .notDetermined)
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            dueDate: date(year: 2026, month: 5, day: 21),
            reminder: nil,
        )

        let didSchedule = try await scheduler.syncReminder(
            for: goal,
            requestsAuthorization: true,
        )

        #expect(didSchedule == false)
        #expect(notificationCenter.requestedAuthorizationOptions == nil)
        #expect(notificationCenter.addedRequests.isEmpty)
        #expect(notificationCenter.removedIdentifiers == [
            scheduler.reminderNotificationIdentifier(for: goal.id),
        ])
    }

    @Test
    func `Syncing denied reminder authorization skips scheduling`() async throws {
        let notificationCenter = FakeNotificationCenter(status: .denied)
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            dueDate: date(year: 2026, month: 5, day: 21),
            reminder: GoalReminder(),
        )

        let didSchedule = try await scheduler.syncReminder(
            for: goal,
            requestsAuthorization: true,
        )

        #expect(didSchedule == false)
        #expect(notificationCenter.addedRequests.isEmpty)
        #expect(notificationCenter.removedIdentifiers == [
            scheduler.reminderNotificationIdentifier(for: goal.id),
        ])
    }

    @Test
    func `Scheduling due date without reminder skips notification request`() async throws {
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            id: goalID,
            dueDate: date(year: 2026, month: 5, day: 21),
        )

        let didSchedule = try await scheduler.scheduleReminder(for: goal)

        #expect(didSchedule == false)
        #expect(notificationCenter.addedRequests.isEmpty)
        #expect(notificationCenter.removedIdentifiers == [
            scheduler.reminderNotificationIdentifier(for: goalID),
        ])
    }

    @Test
    func `Scheduling reminder adds calendar notification request`() async throws {
        let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            id: goalID,
            dueDate: date(year: 2026, month: 5, day: 21),
            reminder: GoalReminder(),
        )

        let didSchedule = try await scheduler.scheduleReminder(for: goal)

        let request = try #require(notificationCenter.addedRequests.first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(didSchedule)
        #expect(notificationCenter.addedRequests.count == 1)
        #expect(request.identifier == scheduler.reminderNotificationIdentifier(for: goalID))
        #expect(request.content.title == "File taxes")
        #expect(request.content.body == "Don't forget to complete by next month")
        #expect(request.content.sound == .default)
        #expect(trigger.dateComponents.year == 2026)
        #expect(trigger.dateComponents.month == 5)
        #expect(trigger.dateComponents.day == 21)
        #expect(trigger.dateComponents.hour == 9)
        #expect(trigger.dateComponents.minute == 0)
        #expect(trigger.repeats == false)
    }

    @Test
    func `Scheduling one-time reminder skips completed goals`() async throws {
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            dueDate: date(year: 2026, month: 5, day: 21),
            reminder: GoalReminder(),
            progress: .outcomeCompleted,
        )

        let didSchedule = try await scheduler.scheduleReminder(for: goal)

        #expect(didSchedule == false)
        #expect(notificationCenter.addedRequests.isEmpty)
        #expect(notificationCenter.removedIdentifiers == [
            scheduler.reminderNotificationIdentifier(for: goal.id),
        ])
    }

    @Test
    func `Scheduling reminder uses today as body for goals due today`() async throws {
        let notificationCenter = FakeNotificationCenter()
        let scheduler = GoalNotificationScheduler(
            notificationCenter: notificationCenter,
            calendar: calendar,
            now: { date(year: 2026, month: 5, day: 21, hour: 8) },
        )
        let goal = makeGoal(
            dueDate: date(year: 2026, month: 5, day: 21),
            reminder: GoalReminder(),
        )

        let didSchedule = try await scheduler.scheduleReminder(for: goal)

        let request = try #require(notificationCenter.addedRequests.first)
        #expect(didSchedule)
        #expect(request.content.title == "File taxes")
        #expect(request.content.body == "Don't forget to complete by today")
    }

    @Test
    func `Scheduling daily recurring reminder repeats every day`() async throws {
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(
            notificationCenter: notificationCenter,
            now: { date(year: 2026, month: 5, day: 21, hour: 8) },
        )
        let goal = makeGoal(
            reminder: GoalReminder(),
            recurrence: GoalRecurrence(cadence: .daily),
        )

        let didSchedule = try await scheduler.scheduleReminder(for: goal)

        let request = try #require(notificationCenter.addedRequests.first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(didSchedule)
        #expect(request.content.body == "Don't forget to complete by today")
        #expect(trigger.repeats)
        #expect(trigger.dateComponents.year == nil)
        #expect(trigger.dateComponents.month == nil)
        #expect(trigger.dateComponents.day == nil)
        #expect(trigger.dateComponents.hour == 9)
        #expect(trigger.dateComponents.minute == 0)
    }

    @Test(
        arguments: [
            (
                GoalRecurrenceCadence.weekly,
                nil as Int?,
                nil as Int?,
                2 as Int?,
                "Don't forget to complete by this week"
            ),
            (
                GoalRecurrenceCadence.monthly,
                nil as Int?,
                1 as Int?,
                nil as Int?,
                "Don't forget to complete by this month"
            ),
            (
                GoalRecurrenceCadence.yearly,
                1 as Int?,
                1 as Int?,
                nil as Int?,
                "Don't forget to complete by this year"
            ),
        ]
    )
    func `Scheduling recurring reminder uses cadence specific repeating trigger and due copy`(
        cadence: GoalRecurrenceCadence,
        expectedMonth: Int?,
        expectedDay: Int?,
        expectedWeekday: Int?,
        expectedBody: String,
    ) async throws {
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(
            notificationCenter: notificationCenter,
            now: { date(year: 2026, month: 5, day: 21, hour: 10) },
        )
        let goal = makeGoal(
            reminder: GoalReminder(),
            recurrence: GoalRecurrence(cadence: cadence),
        )

        let didSchedule = try await scheduler.scheduleReminder(for: goal)

        let request = try #require(notificationCenter.addedRequests.first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(didSchedule)
        #expect(request.content.body == expectedBody)
        #expect(trigger.repeats)
        #expect(trigger.dateComponents.year == nil)
        #expect(trigger.dateComponents.month == expectedMonth)
        #expect(trigger.dateComponents.day == expectedDay)
        #expect(trigger.dateComponents.weekday == expectedWeekday)
        #expect(trigger.dateComponents.hour == 9)
        #expect(trigger.dateComponents.minute == 0)
    }

    @Test
    func `Scheduling completed recurring reminder still repeats`() async throws {
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(
            notificationCenter: notificationCenter,
            now: { date(year: 2026, month: 5, day: 21, hour: 8) },
        )
        let goal = makeGoal(
            reminder: GoalReminder(),
            progress: GoalProgress(
                kind: .outcome,
                events: [
                    GoalProgressEvent(delta: 1, timestamp: date(year: 2026, month: 5, day: 21))
                ],
                targetValue: 1,
            ),
            recurrence: GoalRecurrence(cadence: .daily),
        )

        let didSchedule = try await scheduler.scheduleReminder(for: goal)

        let request = try #require(notificationCenter.addedRequests.first)
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(didSchedule)
        #expect(trigger.repeats)
        #expect(trigger.dateComponents.year == nil)
        #expect(trigger.dateComponents.month == nil)
        #expect(trigger.dateComponents.day == nil)
        #expect(trigger.dateComponents.hour == 9)
    }

    @Test
    func `Syncing recurring reminder without reminder cancels without requesting authorization`() async throws {
        let notificationCenter = FakeNotificationCenter(status: .notDetermined)
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            reminder: nil,
            recurrence: GoalRecurrence(cadence: .daily),
        )

        let didSchedule = try await scheduler.syncReminder(
            for: goal,
            requestsAuthorization: true,
        )

        #expect(didSchedule == false)
        #expect(notificationCenter.requestedAuthorizationOptions == nil)
        #expect(notificationCenter.addedRequests.isEmpty)
        #expect(notificationCenter.removedIdentifiers == [
            scheduler.reminderNotificationIdentifier(for: goal.id),
        ])
    }

    @Test
    func `Scheduling reminder skips goals without due date`() async throws {
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(notificationCenter: notificationCenter)

        let missingDueDate = try await scheduler.scheduleReminder(for: makeGoal(
            reminder: GoalReminder(),
        ))
        let missingReminder = try await scheduler.scheduleReminder(for: makeGoal(
            dueDate: date(year: 2026, month: 5, day: 21),
        ))

        #expect(missingDueDate == false)
        #expect(missingReminder == false)
        #expect(notificationCenter.addedRequests.isEmpty)
    }

    @Test
    func `Scheduling reminder skips past reminder dates`() async throws {
        let notificationCenter = FakeNotificationCenter()
        let scheduler = makeScheduler(notificationCenter: notificationCenter)
        let goal = makeGoal(
            dueDate: date(year: 2025, month: 5, day: 21),
            reminder: GoalReminder(),
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
            scheduler.reminderNotificationIdentifier(for: firstID),
            scheduler.reminderNotificationIdentifier(for: secondID),
        ])
    }

    private func makeScheduler(
        notificationCenter: FakeNotificationCenter,
        now: (() -> Date)? = nil,
    ) -> GoalNotificationScheduler {
        GoalNotificationScheduler(
            notificationCenter: notificationCenter,
            calendar: calendar,
            now: now ?? { date(year: 2026, month: 4, day: 21) },
        )
    }

    private func makeGoal(
        id: UUID = UUID(),
        dueDate: Date? = nil,
        reminder: GoalReminder? = nil,
        progress: GoalProgress = .outcomePending,
        recurrence: GoalRecurrence? = nil,
    ) -> Goal {
        Goal(
            id: id,
            name: "File taxes",
            details: nil,
            dueDate: dueDate,
            reminder: reminder,
            createdAt: date(year: 2026, month: 1, day: 1),
            progress: progress,
            recurrence: recurrence,
        )
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
    ) -> Date {
        calendar.date(
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
