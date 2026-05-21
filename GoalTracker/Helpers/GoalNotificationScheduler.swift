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
    /// Requests notification authorization if needed.
    ///
    /// - Returns: `true` when reminders may be scheduled.
    func requestAuthorizationIfNeeded() async throws -> Bool

    /// Schedules or replaces the pending reminder for a goal.
    ///
    /// - Returns: `true` when a notification request was scheduled.
    @discardableResult
    func scheduleReminder(for goal: Goal) async throws -> Bool

    /// Cancels the pending reminder for a goal.
    func cancelReminder(for goalId: UUID)

    /// Cancels pending reminders for multiple goals.
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
/// This type owns notification request construction and skip rules. It does not persist
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

    /// Schedules a single pending reminder notification for a goal when it is eligible.
    ///
    /// Existing pending reminders for the goal are cancelled first. The goal is skipped when it
    /// is completed, has no due date, has no reminder, or its reminder date is not in the future.
    /// - Returns: `true` when a notification request was scheduled.
    @discardableResult
    func scheduleReminder(for goal: Goal) async throws -> Bool {
        cancelReminder(for: goal.id)
        guard !goal.isCompleted else {
            return false
        }
        guard let dueDate = goal.dueDate,
                let reminder = goal.reminder else {
            return false
        }
        guard let reminderDate = reminder.reminderDate(
            before: dueDate,
            calendar: calendar,
        ) else {
            return false
        }
        guard reminderDate > now() else {
            return false
        }

        let content = reminder.notificationContent(
            goalName: goal.name,
            dueDate: dueDate,
            relativeTo: now(),
            calendar: calendar,
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: reminderDate,
            ),
            repeats: false,
        )
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: goal.id),
            content: content,
            trigger: trigger,
        )
        try await notificationCenter.add(request)
        return true
    }

    /// Cancels the pending reminder notification for a single goal.
    func cancelReminder(for goalId: UUID) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier(for: goalId)],
        )
    }

    /// Cancels pending reminder notifications for multiple goals.
    func cancelReminders(for goalIds: [UUID]) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: goalIds.map(notificationIdentifier(for:)),
        )
    }

    /// Returns the stable pending-notification identifier for a goal reminder.
    func notificationIdentifier(for goalId: UUID) -> String {
        "\(Self.notificationIdentifierPrefix)-\(goalId.uuidString)"
    }
}
