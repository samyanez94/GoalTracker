//
//  GoalReminder.swift
//  GoalTracker
//
//  Created by Codex on 5/21/26.
//

import Foundation
import UserNotifications

/// A reminder configured to fire before a goal's due date.
nonisolated struct GoalReminder: Codable, Hashable {
    /// The local hour used as the due-time anchor when a goal has a due date but no due time.
    static let defaultSettingHour = 9

    let secondsBeforeDueDate: Int

    init(secondsBeforeDueDate: Int) {
        precondition(secondsBeforeDueDate > 0, "Goal reminders must be before the due date.")
        self.secondsBeforeDueDate = secondsBeforeDueDate
    }

    func reminderDate(
        before dueDate: Date,
        dueDateIncludesTime: Bool = false,
        calendar: Calendar = .current,
    ) -> Date? {
        let dueDateAnchor = dueDateIncludesTime ? dueDate : calendar.date(
            bySettingHour: Self.defaultSettingHour,
            minute: 0,
            second: 0,
            of: dueDate,
        )
        guard let dueDateAnchor else {
            return nil
        }
        return calendar.date(
            byAdding: .second,
            value: -secondsBeforeDueDate,
            to: dueDateAnchor,
        )
    }

    /// Creates the local notification content for this reminder.
    func notificationContent(
        goalName: String,
        dueDate: Date,
        relativeTo currentDate: Date = Date(),
        calendar: Calendar = .current,
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = goalName
        let relativeDueDateDescription = Self.relativeDueDateDescription(
            for: dueDate,
            relativeTo: currentDate,
            calendar: calendar,
        )
        content.body = "Complete by \(relativeDueDateDescription.lowercased())"
        content.sound = .default
        return content
    }

    private static func relativeDueDateDescription(
        for dueDate: Date,
        relativeTo currentDate: Date,
        calendar: Calendar,
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
                time: .omitted
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

    static func daysBeforeDueDate(_ days: Int) -> GoalReminder {
        GoalReminder(
            secondsBeforeDueDate: days * 24 * 60 * 60,
        )
    }

    static func hoursBeforeDueDate(_ hours: Int) -> GoalReminder {
        GoalReminder(
            secondsBeforeDueDate: hours * 60 * 60,
        )
    }

    static func minutesBeforeDueDate(_ minutes: Int) -> GoalReminder {
        GoalReminder(
            secondsBeforeDueDate: minutes * 60,
        )
    }
}
