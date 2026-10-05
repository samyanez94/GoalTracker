//
//  ModelTestSupport.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/31/26.
//

import Foundation

enum ModelTestSupport {
	static var calendar: Calendar {
		var calendar = Calendar(identifier: .gregorian)
		guard let timeZone = TimeZone(secondsFromGMT: 0) else {
			preconditionFailure("Unable to create GMT test time zone.")
		}
		calendar.timeZone = timeZone
		calendar.firstWeekday = 2
		return calendar
	}

	static func date(
		year: Int,
		month: Int,
		day: Int,
		hour: Int = 0,
	) -> Date {
		let calendar = Self.calendar
		let components = DateComponents(
			calendar: calendar,
			timeZone: calendar.timeZone,
			year: year,
			month: month,
			day: day,
			hour: hour,
		)
		guard let date = components.date else {
			preconditionFailure("Invalid test date.")
		}
		return date
	}
}
