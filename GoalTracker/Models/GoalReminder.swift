//
//  GoalReminder.swift
//  GoalTracker
//
//  Created by Codex on 5/21/26.
//

import Foundation

/// A reminder configured to fire on a goal's due date.
nonisolated struct GoalReminder: Codable, Hashable {
    /// The local hour used as the due-time anchor when a goal has a due date but no due time.
    static let defaultSettingHour = 9

    init() {}

    func fireDate(
        on dueDate: Date,
        calendar: Calendar = .current,
    ) -> Date? {
        calendar.date(
            bySettingHour: Self.defaultSettingHour,
            minute: 0,
            second: 0,
            of: dueDate,
        )
    }
}
