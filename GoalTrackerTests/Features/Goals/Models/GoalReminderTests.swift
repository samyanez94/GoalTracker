//
//  GoalReminderTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/21/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalReminderTests {
	@Test
	func `Date only reminders calculate from nine AM local time`() throws {
		let calendar = Calendar(identifier: .gregorian)
		let targetDate = try #require(
			calendar.date(
				from: DateComponents(
					year: 2026,
					month: 5,
					day: 21,
				)
			)
		)

		#expect(
			GoalReminder().fireDate(on: targetDate, calendar: calendar)
				== calendar.date(
					from: DateComponents(year: 2026, month: 5, day: 21, hour: 9),
				)
		)
	}
}
