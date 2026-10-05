//
//  OutcomeProgressTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 6/1/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct OutcomeProgressTests {
	@Test
	func `Pending outcome progress starts empty`() {
		let progress = OutcomeProgress()

		#expect(progress.events.isEmpty)
		#expect(progress.currentValue == 0)
		#expect(progress.isCompleted == false)
		#expect(progress.fractionCompleted == 0)
	}

	@Test
	func `Completed outcome progress uses supplied timestamp`() throws {
		let timestamp = Date(timeIntervalSinceReferenceDate: 123)

		let progress = OutcomeProgress.completed(timestamp: timestamp)
		let event = try #require(progress.events.first)

		#expect(progress.currentValue == 1)
		#expect(progress.isCompleted)
		#expect(progress.fractionCompleted == 1)
		#expect(event.timestamp == timestamp)
	}

	@Test
	func `Complete and reset append binary deltas`() throws {
		var progress = OutcomeProgress()
		let completedAt = Date(timeIntervalSinceReferenceDate: 123)
		let resetAt = Date(timeIntervalSinceReferenceDate: 456)

		let didComplete = progress.complete(timestamp: completedAt)
		let didReset = progress.reset(timestamp: resetAt)

		#expect(didComplete)
		#expect(didReset)
		#expect(progress.currentValue == 0)
		#expect(progress.events.map(\.delta) == [1, -1])
		#expect(progress.events.map(\.timestamp) == [completedAt, resetAt])
	}

	@Test
	func `Completion methods report false when already at bounds`() {
		var progress = OutcomeProgress()

		let resetAtZeroChanged = progress.reset()
		progress.complete()
		let completeAtOneChanged = progress.complete()

		#expect(resetAtZeroChanged == false)
		#expect(completeAtOneChanged == false)
		#expect(progress.currentValue == 1)
		#expect(progress.events.map(\.delta) == [1])
	}

	@Test
	func `Period completion uses only current period events`() {
		let period = DateInterval(
			start: Date(timeIntervalSinceReferenceDate: 100),
			end: Date(timeIntervalSinceReferenceDate: 200),
		)
		let progress = OutcomeProgress(
			events: [
				GoalProgressEvent(delta: 1, timestamp: Date(timeIntervalSinceReferenceDate: 50)),
				GoalProgressEvent(delta: 1, timestamp: Date(timeIntervalSinceReferenceDate: 150))
			]
		)

		#expect(progress.currentValue(in: period) == 1)
		#expect(progress.isCompleted(in: period))
		#expect(progress.fractionCompleted(in: period) == 1)
	}

	@Test
	func `Invalid outcome progress events throw a data corrupted error`() {
		#expect(throws: DecodingError.self) {
			try decodeOutcomeProgress(
				"""
				{
				    "events": [
				        {
				            "delta": 0.5,
				            "timestamp": 0
				        }
				    ]
				}
				""",
			)
		}
	}

	private func decodeOutcomeProgress(_ json: String) throws -> OutcomeProgress {
		let data = try #require(json.data(using: .utf8))
		return try JSONDecoder().decode(OutcomeProgress.self, from: data)
	}
}
