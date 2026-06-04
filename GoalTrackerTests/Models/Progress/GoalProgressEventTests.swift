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
		let id = UUID()
		let timestamp = Date(timeIntervalSinceReferenceDate: 123)

		let event = GoalProgressEvent(id: id, delta: 4, timestamp: timestamp)

		#expect(event.id == id)
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

	@Test
	func `Progress events decode legacy payloads without an id`() throws {
		let data = try #require(
			"""
			{
			    "delta": 4,
			    "timestamp": 123
			}
			""".data(using: .utf8)
		)

		let event = try JSONDecoder().decode(GoalProgressEvent.self, from: data)
		let zeroID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000000"))

		#expect(event.id != zeroID)
		#expect(event.delta == 4)
		#expect(event.timestamp == Date(timeIntervalSinceReferenceDate: 123))
	}
}
