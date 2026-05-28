//
//  GoalRecurrence.swift
//  GoalTracker
//
//  Created by Codex on 5/28/26.
//

import Foundation

/// Describes how often a goal's progress starts a new completion period.
nonisolated struct GoalRecurrence: Codable, Equatable, Hashable {
    /// The cadence used to determine the active progress period.
    ///
    /// Future custom cadences should extend this value with additional optional
    /// configuration fields while preserving the built-in cadence values.
    var cadence: GoalRecurrenceCadence

    init(cadence: GoalRecurrenceCadence) {
        self.cadence = cadence
    }

    var displayTitle: String {
        cadence.displayTitle
    }

    func period(
        containing date: Date,
        calendar: Calendar = .current,
    ) -> DateInterval? {
        cadence.period(containing: date, calendar: calendar)
    }
}
