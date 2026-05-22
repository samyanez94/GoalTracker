//
//  GoalReminderPreset.swift
//  GoalTracker
//
//  Created by Codex on 5/21/26.
//

import Foundation

nonisolated enum GoalReminderPreset: String, Codable, Hashable, CaseIterable, Identifiable {
    case oneDayBefore
    case oneWeekBefore
    case oneMonthBefore

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .oneDayBefore:
            "1 day before"
        case .oneWeekBefore:
            "1 week before"
        case .oneMonthBefore:
            "1 month before"
        }
    }

    var earlyReminder: GoalReminder {
        switch self {
        case .oneDayBefore:
            .daysBeforeDueDate(1)
        case .oneWeekBefore:
            .daysBeforeDueDate(7)
        case .oneMonthBefore:
            .daysBeforeDueDate(30)
        }
    }

    static func preset(for earlyReminder: GoalReminder) -> GoalReminderPreset? {
        allCases.first { preset in
            preset.earlyReminder == earlyReminder
        }
    }
}
