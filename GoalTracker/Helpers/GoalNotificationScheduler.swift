//
//  GoalNotificationScheduler.swift
//  GoalTracker
//
//  Created by Codex on 5/21/26.
//

import Foundation
import UserNotifications

/// The small notification-center surface GoalTracker needs for reminder scheduling.
///
/// Keeping this protocol narrow lets scheduler tests verify notification requests without
/// talking to the process-wide `UNUserNotificationCenter`.
@MainActor
protocol GoalNotificationCenterClient {
    /// Returns the app's current notification authorization state.
    func authorizationStatus() async -> GoalNotificationAuthorizationStatus

    /// Asks the user for notification authorization with the requested options.
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool

    /// Adds a pending notification request.
    func add(_ request: UNNotificationRequest) async throws

    /// Removes pending notification requests for the provided identifiers.
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

/// GoalTracker's simplified notification authorization states.
enum GoalNotificationAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
}

/// The reminder scheduling behavior `GoalManager` needs when goal state changes.
@MainActor
protocol GoalReminderScheduling {
    /// Reconciles the pending reminder notification with the goal's current reminder state.
    ///
    /// - Returns: `true` when a notification request was scheduled.
    @discardableResult
    func syncReminder(
        for state: GoalReminderSyncState,
        requestsAuthorization: Bool,
    ) async throws -> Bool

    /// Cancels pending reminder notifications for multiple goals.
    func cancelReminders(for goalIds: [UUID])
}

extension UNUserNotificationCenter: GoalNotificationCenterClient {
    func authorizationStatus() async -> GoalNotificationAuthorizationStatus {
        switch await notificationSettings().authorizationStatus {
        case .notDetermined:
            .notDetermined
        case .denied:
            .denied
        case .authorized, .provisional, .ephemeral:
            .authorized
        @unknown default:
            .denied
        }
    }
}

/// Schedules and cancels local notification reminders for goals.
///
/// This type owns notification request construction and authorization. It does not persist
/// goals or decide when goal changes should trigger scheduling.
@MainActor
struct GoalNotificationScheduler: GoalReminderScheduling {
    private static let notificationIdentifierPrefix = "goal-reminder"

    private let notificationCenter: GoalNotificationCenterClient
    
    private let calendar: Calendar
    
    private let now: () -> Date

    init(
        notificationCenter: GoalNotificationCenterClient = UNUserNotificationCenter.current(),
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init,
    ) {
        self.notificationCenter = notificationCenter
        self.calendar = calendar
        self.now = now
    }

    /// Requests notification authorization only when the user has not answered yet.
    ///
    /// - Returns: `true` when notifications are authorized after the check, otherwise `false`.
    func requestAuthorizationIfNeeded() async throws -> Bool {
        switch await notificationCenter.authorizationStatus() {
        case .notDetermined:
            try await notificationCenter.requestAuthorization(options: [.alert, .sound])
        case .denied:
            false
        case .authorized:
            true
        }
    }

    /// Reconciles the pending reminder notification with the goal's current reminder state.
    ///
    /// Existing pending reminders for the goal are cancelled first. If the goal cannot produce
    /// a future reminder, no replacement notification is scheduled.
    /// - Returns: `true` when a notification request was scheduled.
    @discardableResult
    func syncReminder(
        for state: GoalReminderSyncState,
        requestsAuthorization: Bool,
    ) async throws -> Bool {
        cancelReminder(for: state.goalId)

        let currentDate = now()
        guard let schedule = reminderSchedule(
            state: state,
            currentDate: currentDate,
        ) else {
            return false
        }

        if requestsAuthorization {
            guard try await requestAuthorizationIfNeeded() else {
                return false
            }
        }

        try await scheduleReminder(schedule, currentDate: currentDate)
        return true
    }

    /// Reconciles the pending reminder notification with a goal's current reminder state.
    ///
    /// This convenience overload snapshots the model before starting async work.
    /// - Returns: `true` when a notification request was scheduled.
    @discardableResult
    func syncReminder(for goal: Goal, requestsAuthorization: Bool) async throws -> Bool {
        try await syncReminder(
            for: GoalReminderSyncState(goal: goal),
            requestsAuthorization: requestsAuthorization,
        )
    }

    /// Schedules pending reminder notifications for a goal when they are eligible.
    ///
    /// Existing pending reminders for the goal are cancelled first.
    /// - Returns: `true` when a notification request was scheduled.
    @discardableResult
    func scheduleReminder(for goal: Goal) async throws -> Bool {
        try await syncReminder(for: goal, requestsAuthorization: false)
    }

    private func reminderSchedule(
        state: GoalReminderSyncState,
        currentDate: Date,
    ) -> GoalReminderSchedule? {
        GoalReminderSchedule.reminder(
            state: state,
            calendar: calendar,
            currentDate: currentDate,
        )
    }

    private func scheduleReminder(
        _ schedule: GoalReminderSchedule,
        currentDate: Date,
    ) async throws {
        let content = notificationContent(for: schedule, relativeTo: currentDate)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: schedule.triggerDateComponents,
            repeats: schedule.repeats,
        )
        let request = UNNotificationRequest(
            identifier: reminderNotificationIdentifier(for: schedule.goalId),
            content: content,
            trigger: trigger,
        )
        try await notificationCenter.add(request)
    }

    private func notificationContent(
        for schedule: GoalReminderSchedule,
        relativeTo currentDate: Date,
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = schedule.goalName
        content.body = notificationBody(for: schedule, relativeTo: currentDate)
        content.sound = .default
        return content
    }

    private func notificationBody(
        for schedule: GoalReminderSchedule,
        relativeTo currentDate: Date,
    ) -> String {
        let dueDescription = switch schedule.dueDescription {
        case .date(let dueDate):
            relativeDueDateDescription(
                for: dueDate,
                relativeTo: currentDate,
            )
            .lowercased()
        case .cadence(let cadence):
            cadence.reminderDueDescription
        }
        return "Don't forget to complete by \(dueDescription)"
    }

    private func relativeDueDateDescription(
        for dueDate: Date,
        relativeTo currentDate: Date,
    ) -> String {
        let currentDay = calendar.startOfDay(for: currentDate)
        let dueDay = calendar.startOfDay(for: dueDate)
        guard !calendar.isDate(dueDay, inSameDayAs: currentDay) else {
            return "Today"
        }
        if isExactOffset(.day, value: 1, from: currentDay, to: dueDay) {
            return "Tomorrow"
        }
        if isExactOffset(.weekOfYear, value: 1, from: currentDay, to: dueDay) {
            return "Next week"
        }
        if isExactOffset(.month, value: 1, from: currentDay, to: dueDay) {
            return "Next month"
        }
        if isExactOffset(.year, value: 1, from: currentDay, to: dueDay) {
            return "Next year"
        }
        return dueDate.formatted(date: .abbreviated, time: .omitted)
    }

    private func isExactOffset(
        _ component: Calendar.Component,
        value: Int,
        from startDate: Date,
        to endDate: Date,
    ) -> Bool {
        calendar.date(byAdding: component, value: value, to: startDate) == endDate
    }

    /// Cancels the pending reminder notification for a single goal.
    func cancelReminder(for goalId: UUID) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: notificationIdentifiers(for: goalId),
        )
    }

    /// Cancels pending reminder notifications for multiple goals.
    func cancelReminders(for goalIds: [UUID]) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: goalIds.flatMap(notificationIdentifiers(for:)),
        )
    }

    /// Returns the stable pending-notification identifier for a goal's reminder.
    func reminderNotificationIdentifier(for goalId: UUID) -> String {
        "\(Self.notificationIdentifierPrefix)-\(goalId.uuidString)"
    }

    private func notificationIdentifiers(for goalId: UUID) -> [String] {
        [reminderNotificationIdentifier(for: goalId)]
    }
}
