//
//  GoalProgressEventFormatterTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 6/3/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalProgressEventFormatterTests {
	@Test
	func `Positive event without unit says increased by number`() {
		let event = GoalProgressEvent(delta: 5, timestamp: Date())

		let title = GoalProgressEventFormatter.title(for: event, unit: nil)

		#expect(title == "Increased by 5")
	}

	@Test
	func `Negative event without unit says decreased by absolute number`() {
		let event = GoalProgressEvent(delta: -2, timestamp: Date())

		let title = GoalProgressEventFormatter.title(for: event, unit: nil)

		#expect(title == "Decreased by 2")
	}

	@Test
	func `Prefix unit appears before the amount`() {
		let event = GoalProgressEvent(delta: 10, timestamp: Date())

		let title = GoalProgressEventFormatter.title(for: event, unit: .dollars)

		#expect(title == "Increased by $10")
	}

	@Test
	func `Suffix unit appears after the amount`() {
		let event = GoalProgressEvent(delta: -3, timestamp: Date())

		let title = GoalProgressEventFormatter.title(for: event, unit: .kilometers)

		#expect(title == "Decreased by 3 km")
	}

	@Test
	func `Fractional amount remains readable`() {
		let event = GoalProgressEvent(delta: 2.5, timestamp: Date())

		let title = GoalProgressEventFormatter.title(for: event, unit: nil)

		#expect(title == "Increased by 2.5")
	}
}
