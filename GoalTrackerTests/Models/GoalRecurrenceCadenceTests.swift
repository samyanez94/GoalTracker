//
//  GoalRecurrenceCadenceTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/28/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalRecurrenceCadenceTests {
	@Test(
		arguments: [
			(
				GoalRecurrenceCadence.daily,
				"Daily",
				"Repeats every day",
				"Every day"
			),
			(
				.weekly,
				"Weekly",
				"Repeats every week",
				"Every week"
			),
			(
				.monthly,
				"Monthly",
				"Repeats every month",
				"Every month"
			),
			(
				.yearly,
				"Yearly",
				"Repeats every year",
				"Every year"
			)
		],
	)
	func `Cadence titles describe each cadence`(
		cadence: GoalRecurrenceCadence,
		expectedDisplayTitle: String,
		expectedDetailTitle: String,
		expectedRowTitle: String,
	) {
		#expect(String(localized: cadence.displayTitle) == expectedDisplayTitle)
		#expect(String(localized: cadence.detailTitle) == expectedDetailTitle)
		#expect(String(localized: cadence.rowTitle) == expectedRowTitle)
	}

	@Test(
		arguments: [
			(
				GoalRecurrenceCadence.daily,
				ModelTestSupport.date(year: 2026, month: 5, day: 28),
				ModelTestSupport.date(year: 2026, month: 5, day: 29)
			),
			(
				GoalRecurrenceCadence.weekly,
				ModelTestSupport.date(year: 2026, month: 5, day: 25),
				ModelTestSupport.date(year: 2026, month: 6, day: 1)
			),
			(
				GoalRecurrenceCadence.monthly,
				ModelTestSupport.date(year: 2026, month: 5, day: 1),
				ModelTestSupport.date(year: 2026, month: 6, day: 1)
			),
			(
				GoalRecurrenceCadence.yearly,
				ModelTestSupport.date(year: 2026, month: 1, day: 1),
				ModelTestSupport.date(year: 2027, month: 1, day: 1)
			)
		],
	)
	func `Cadence uses calendar period boundaries`(
		cadence: GoalRecurrenceCadence,
		expectedStart: Date,
		expectedEnd: Date,
	) throws {
		let period = try #require(
			cadence.period(
				containing: ModelTestSupport.date(year: 2026, month: 5, day: 28, hour: 14),
				calendar: ModelTestSupport.calendar,
			)
		)

		#expect(period.start == expectedStart)
		#expect(period.end == expectedEnd)
	}

	@Test
	func `Cadence can resolve the previous period`() throws {
		let currentPeriod = try #require(
			GoalRecurrenceCadence.monthly.period(
				containing: ModelTestSupport.date(year: 2026, month: 1, day: 28),
				calendar: ModelTestSupport.calendar,
			)
		)
		let previousPeriod = try #require(
			GoalRecurrenceCadence.monthly.period(
				before: currentPeriod,
				calendar: ModelTestSupport.calendar,
			)
		)

		#expect(previousPeriod.start == ModelTestSupport.date(year: 2025, month: 12, day: 1))
		#expect(previousPeriod.end == ModelTestSupport.date(year: 2026, month: 1, day: 1))
	}

	@Test(
		arguments: [
			(GoalRecurrenceCadence.daily, "today"),
			(.weekly, "this week"),
			(.monthly, "this month"),
			(.yearly, "this year")
		],
	)
	func `Cadence reminder target descriptions match user facing cadence`(
		cadence: GoalRecurrenceCadence,
		expectedDescription: String,
	) {
		#expect(String(localized: cadence.reminderTargetDescription) == expectedDescription)
	}

	@Test
	func `Cadence reminder components match period starts at default hour`() {
		#expect(
			GoalRecurrenceCadence.daily
				.reminderDateComponents(calendar: ModelTestSupport.calendar)
				.hour == 9
		)
		#expect(
			GoalRecurrenceCadence.weekly
				.reminderDateComponents(calendar: ModelTestSupport.calendar)
				.weekday == 2
		)
		#expect(
			GoalRecurrenceCadence.monthly
				.reminderDateComponents(calendar: ModelTestSupport.calendar)
				.day == 1
		)
		#expect(
			GoalRecurrenceCadence.yearly
				.reminderDateComponents(calendar: ModelTestSupport.calendar)
				.month == 1
		)
		#expect(
			GoalRecurrenceCadence.yearly
				.reminderDateComponents(calendar: ModelTestSupport.calendar)
				.day == 1
		)
	}

	@Test(
		arguments: [
			(GoalRecurrenceCadence.daily, 1, "1 day"),
			(.weekly, 5, "5 weeks"),
			(.monthly, 1, "1 month"),
			(.yearly, 5, "5 years")
		],
	)
	func `Streak value titles pluralize cadence units`(
		cadence: GoalRecurrenceCadence,
		count: Int,
		expectedTitle: String,
	) {
		#expect(cadence.streakValueTitle(for: count) == expectedTitle)
	}
}
