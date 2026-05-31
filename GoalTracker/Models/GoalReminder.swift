//
//  GoalReminder.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/21/26.
//

import Foundation

/// A reminder configured to fire at the app's default reminder time.
nonisolated struct GoalReminder: Codable, Hashable {
	/// The local hour used as the reminder-time anchor for goals without a custom reminder time.
	static let defaultSettingHour = 9

	init() {}

	func fireDate(on date: Date, calendar: Calendar = .current, ) -> Date? {
		calendar.date(bySettingHour: Self.defaultSettingHour, minute: 0, second: 0, of: date, )
	}
}
