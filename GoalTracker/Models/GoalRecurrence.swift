//
//  GoalRecurrence.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/28/26.
//

import Foundation

/// Defines how a recurring goal resets its progress window.
///
/// A recurrence turns the goal's event history into calendar-based completion periods, such as the current day, week, month, or year.
nonisolated struct GoalRecurrence: Codable, Equatable, Hashable {
	/// The repeat interval used to find the active completion period.
	var cadence: GoalRecurrenceCadence

	init(cadence: GoalRecurrenceCadence) {
		self.cadence = cadence
	}

	var detailTitle: String {
		cadence.detailTitle
	}

	var rowTitle: String {
		cadence.rowTitle
	}

	func period(
		containing date: Date,
		calendar: Calendar = .current,
	) -> DateInterval? {
		cadence.period(containing: date, calendar: calendar)
	}

	func period(
		before period: DateInterval,
		calendar: Calendar = .current,
	) -> DateInterval? {
		cadence.period(before: period, calendar: calendar)
	}

}
