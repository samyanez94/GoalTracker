//
//  GoalProgressEventTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 6/1/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalProgressEventTests {
	@Test
	func `Progress events store delta and timestamp`() {
		let timestamp = Date(timeIntervalSinceReferenceDate: 123)

		let event = GoalProgressEvent(delta: 4, timestamp: timestamp)

		#expect(event.delta == 4)
		#expect(event.timestamp == timestamp)
	}

	@Test
	func `Progress events round trip through Codable`() throws {
		let event = GoalProgressEvent(
			delta: -2,
			timestamp: Date(timeIntervalSinceReferenceDate: 456),
		)

		let data = try JSONEncoder().encode(event)
		let decodedEvent = try JSONDecoder().decode(GoalProgressEvent.self, from: data)

		#expect(decodedEvent == event)
	}
}
