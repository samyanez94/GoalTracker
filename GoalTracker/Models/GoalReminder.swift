//
//  GoalReminder.swift
//  GoalTracker
//
//  Created by Codex on 5/21/26.
//

import Foundation

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
