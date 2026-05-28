//
//  GoalRecurrenceCadence.swift
//  GoalTracker
//
//  Created by Codex on 5/28/26.
//

import Foundation

/// The cadence used to group progress events for recurring completion.
nonisolated enum GoalRecurrenceCadence: String, Codable, Equatable, Hashable {
    case daily
    case weekly
    case monthly
    case yearly

    static let builtInOptions: [GoalRecurrenceCadence] = [
        .daily,
        .weekly,
        .monthly,
        .yearly,
    ]

    var displayTitle: String {
        switch self {
        case .daily:
            "Daily"
        case .weekly:
            "Weekly"
        case .monthly:
            "Monthly"
        case .yearly:
            "Yearly"
        }
    }

    func period(
        containing date: Date,
        calendar: Calendar = .current,
    ) -> DateInterval? {
        switch self {
        case .daily:
            calendar.dateInterval(of: .day, for: date)
        case .weekly:
            calendar.dateInterval(of: .weekOfYear, for: date)
        case .monthly:
            calendar.dateInterval(of: .month, for: date)
        case .yearly:
            calendar.dateInterval(of: .year, for: date)
        }
    }
}
