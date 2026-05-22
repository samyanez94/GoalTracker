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
    /// a future due-date or early reminder, no replacement notifications are scheduled.
    /// - Returns: `true` when a notification request was scheduled.
    @discardableResult
    func syncReminder(
        for state: GoalReminderSyncState,
        requestsAuthorization: Bool,
    ) async throws -> Bool {
        cancelReminder(for: state.goalId)

        let currentDate = now()
        let schedules = reminderSchedules(
            state: state,
            currentDate: currentDate,
        )
        guard !schedules.isEmpty else {
            return false
        }

        if requestsAuthorization {
            guard try await requestAuthorizationIfNeeded() else {
                return false
            }
        }

        for schedule in schedules {
            try await scheduleReminder(schedule, currentDate: currentDate)
        }
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
    /// - Returns: `true` when at least one notification request was scheduled.
    @discardableResult
    func scheduleReminder(for goal: Goal) async throws -> Bool {
        try await syncReminder(for: goal, requestsAuthorization: false)
    }

    private func reminderSchedules(
        state: GoalReminderSyncState,
        currentDate: Date,
    ) -> [GoalReminderSchedule] {
        [
            GoalReminderSchedule.dueDateReminder(
                state: state,
                calendar: calendar,
                currentDate: currentDate,
            ),
            GoalReminderSchedule.earlyReminder(
                state: state,
                calendar: calendar,
                currentDate: currentDate,
            ),
        ].compactMap { $0 }
    }

    private func scheduleReminder(
        _ schedule: GoalReminderSchedule,
        currentDate: Date,
    ) async throws {
        let content = notificationContent(for: schedule, relativeTo: currentDate)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: schedule.fireDate,
            ),
            repeats: false,
        )
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: schedule.goalId, kind: schedule.kind),
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
        let relativeDueDateDescription = relativeDueDateDescription(
            for: schedule.dueDate,
            relativeTo: currentDate,
        )
        content.body = "Complete by \(relativeDueDateDescription.lowercased())"
        content.sound = .default
        return content
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
        let dayOffset = calendar.dateComponents([.day], from: currentDay, to: dueDay).day
        guard let dayOffset,
              let displayDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else {
            return dueDate.formatted(
                date: .abbreviated,
                time: .omitted,
            )
        }
        return displayDate.formatted(
            Date.RelativeFormatStyle(
                presentation: .named,
                unitsStyle: .wide,
                capitalizationContext: .beginningOfSentence,
            ),
        )
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

    /// Returns the stable pending-notification identifier for a goal's automatic due-date reminder.
    func dueDateNotificationIdentifier(for goalId: UUID) -> String {
        notificationIdentifier(for: goalId, kind: .dueDate)
    }

    /// Returns the stable pending-notification identifier for a goal's optional early reminder.
    func earlyReminderNotificationIdentifier(for goalId: UUID) -> String {
        notificationIdentifier(for: goalId, kind: .early)
    }

    private func notificationIdentifiers(for goalId: UUID) -> [String] {
        [
            dueDateNotificationIdentifier(for: goalId),
            earlyReminderNotificationIdentifier(for: goalId),
        ]
    }

    private func notificationIdentifier(
        for goalId: UUID,
        kind: GoalReminderSchedule.Kind,
    ) -> String {
        let kindValue = switch kind {
        case .dueDate:
            "due-date"
        case .early:
            "early"
        }
        return "\(Self.notificationIdentifierPrefix)-\(kindValue)-\(goalId.uuidString)"
    }
}
