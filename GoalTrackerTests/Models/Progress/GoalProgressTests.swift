//
//  GoalProgressTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/12/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalProgressTests {
	@Test
	func `Outcome progress exposes binary progress`() {
		#expect(GoalProgress.outcome(OutcomeProgress()).outcomeProgress != nil)
		#expect(GoalProgress.outcome(OutcomeProgress()).measurableProgress == nil)
		#expect(GoalProgress.outcome(OutcomeProgress()).events.isEmpty)
		#expect(GoalProgress.outcome(OutcomeProgress()).fractionCompleted == 0)
		#expect(GoalProgress.outcome(OutcomeProgress.completed(timestamp: Date())).fractionCompleted == 1)
	}

	@Test
	func `Measurable progress exposes measurable progress`() throws {
		let progress = GoalProgress.measurable(
			currentValue: 4,
			targetValue: 10,
			step: 2,
		)
		let measurableProgress = try #require(progress.measurableProgress)

		#expect(progress.isMeasurable)
		#expect(progress.outcomeProgress == nil)
		#expect(measurableProgress.currentValue == 4)
		#expect(measurableProgress.targetValue == 10)
		#expect(measurableProgress.step == 2)
	}

	@Test
	func `Outcome progress does not step incrementally`() {
		var progress = GoalProgress.outcome(OutcomeProgress())

		let didIncrement = progress.increment()
		let didDecrement = progress.decrement()

		#expect(didIncrement == false)
		#expect(didDecrement == false)
		#expect(progress.currentValue == 0)
		#expect(progress.events.isEmpty)
	}

	@Test
	func `Updated progress preserves events when current value is unchanged`() throws {
		let originalTimestamp = Date(timeIntervalSinceReferenceDate: 123)
		let previousProgress = GoalProgress.measurable(
			currentValue: 4,
			targetValue: 10,
			step: 2,
			timestamp: originalTimestamp,
		)
		let editedProgress = GoalProgress.measurable(currentValue: 4, targetValue: 12, step: 3)

		let updatedProgress = editedProgress.updated(preservingEventsFrom: previousProgress)
		let measurableProgress = try #require(updatedProgress.measurableProgress)

		#expect(measurableProgress.currentValue == 4)
		#expect(measurableProgress.targetValue == 12)
		#expect(measurableProgress.step == 3)
		#expect(measurableProgress.events.count == 1)
		#expect(measurableProgress.events.first?.timestamp == originalTimestamp)
	}

	@Test
	func `Updated progress preserves events when edited current value differs`() {
		let previousProgress = GoalProgress.measurable(currentValue: 4, targetValue: 10)
		let editedProgress = GoalProgress.measurable(currentValue: 7, targetValue: 10)

		let updatedProgress = editedProgress.updated(preservingEventsFrom: previousProgress)

		#expect(updatedProgress.currentValue == 4)
		#expect(updatedProgress.events.map(\.delta) == [4])
	}

	@Test
	func `Progress values round trip through Codable`() throws {
		let progress = GoalProgress.measurable(
			currentValue: 4,
			targetValue: 10,
			step: 2,
			timestamp: Date(timeIntervalSinceReferenceDate: 123),
		)

		let decodedProgress = try roundTrip(progress)
		let measurableProgress = try #require(decodedProgress.measurableProgress)

		#expect(measurableProgress.events.map(\.delta) == [4])
		#expect(measurableProgress.currentValue == 4)
		#expect(measurableProgress.targetValue == 10)
		#expect(measurableProgress.step == 2)
	}

	private func roundTrip(_ progress: GoalProgress) throws -> GoalProgress {
		let data = try JSONEncoder().encode(progress)
		return try JSONDecoder().decode(GoalProgress.self, from: data)
	}
}
