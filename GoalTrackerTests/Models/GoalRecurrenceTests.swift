//
//  GoalRecurrenceTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/28/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalRecurrenceTests {
	@Test
	func `Recurrence encodes cadence as a stable value`() throws {
		let recurrence = GoalRecurrence(cadence: .weekly)
		let data = try JSONEncoder().encode(recurrence)
		let json = String(decoding: data, as: UTF8.self)

		#expect(json.contains(#""cadence":"weekly""#))
	}

	@Test(
		arguments: [
			(GoalRecurrenceCadence.daily, "Repeats every day"),
			(.weekly, "Repeats every week"),
			(.monthly, "Repeats every month"),
			(.yearly, "Repeats every year")
		],
	)
	func `Recurrence detail titles describe cadence`(
		cadence: GoalRecurrenceCadence,
		expectedDetailTitle: String,
	) {
		let recurrence = GoalRecurrence(cadence: cadence)

		#expect(recurrence.detailTitle == expectedDetailTitle)
	}
}
