//
//  MeasurableProgressTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 6/1/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct MeasurableProgressTests {
	// MARK: - Initialization

	@Test
	func `Measurable progress stores initial value as a timestamped event`() throws {
		let timestamp = Date(timeIntervalSinceReferenceDate: 123)

		let progress = makeProgress(
			currentValue: 3,
			targetValue: 10,
			timestamp: timestamp,
		)

		let event = try #require(progress.events.first)
		#expect(progress.events.count == 1)
		#expect(event.delta == 3)
		#expect(event.timestamp == timestamp)
		#expect(progress.currentValue == 3)
	}

	@Test
	func `Zero progress stores no events`() {
		let progress = makeProgress(currentValue: 0, targetValue: 10)

		#expect(progress.events.isEmpty)
		#expect(progress.currentValue == 0)
	}

	// MARK: - Mutations

	@Test
	func `Complete appends delta to target`() throws {
		var progress = makeProgress(currentValue: 3, targetValue: 10)
		let timestamp = Date(timeIntervalSinceReferenceDate: 456)

		let didChange = progress.complete(timestamp: timestamp)

		let event = try #require(progress.events.last)
		#expect(didChange == true)
		#expect(progress.currentValue == 10)
		#expect(event.delta == 7)
		#expect(event.timestamp == timestamp)
	}

	@Test
	func `Reset appends negative delta to zero`() throws {
		var progress = makeProgress(currentValue: 3, targetValue: 10)
		let timestamp = Date(timeIntervalSinceReferenceDate: 456)

		let didChange = progress.reset(timestamp: timestamp)

		let event = try #require(progress.events.last)
		#expect(didChange == true)
		#expect(progress.currentValue == 0)
		#expect(event.delta == -3)
		#expect(event.timestamp == timestamp)
	}

	@Test
	func `Increment increases current value by step`() throws {
		var progress = makeProgress(currentValue: 2, targetValue: 10, step: 2.5)
		let timestamp = Date(timeIntervalSinceReferenceDate: 456)

		let didChange = progress.increment(timestamp: timestamp)

		let event = try #require(progress.events.last)
		#expect(didChange == true)
		#expect(progress.currentValue == 4.5)
		#expect(event.delta == 2.5)
		#expect(event.timestamp == timestamp)
	}

	@Test
	func `Decrement decreases current value by step`() throws {
		var progress = makeProgress(currentValue: 6, targetValue: 10, step: 2.5)
		let timestamp = Date(timeIntervalSinceReferenceDate: 456)

		let didChange = progress.decrement(timestamp: timestamp)

		let event = try #require(progress.events.last)
		#expect(didChange)
		#expect(progress.currentValue == 3.5)
		#expect(event.delta == -2.5)
		#expect(event.timestamp == timestamp)
	}

	@Test
	func `Increment clamps at target value`() throws {
		var progress = makeProgress(currentValue: 8, targetValue: 10, step: 5)

		let didChange = progress.increment()

		let event = try #require(progress.events.last)
		#expect(didChange)
		#expect(progress.currentValue == 10)
		#expect(event.delta == 2)
	}

	@Test
	func `Decrement clamps at zero`() throws {
		var progress = makeProgress(currentValue: 2, targetValue: 10, step: 5)

		let didChange = progress.decrement()

		let event = try #require(progress.events.last)
		#expect(didChange)
		#expect(progress.currentValue == 0)
		#expect(event.delta == -2)
	}

	@Test
	func `Custom update increases current value by amount`() throws {
		var progress = makeProgress(currentValue: 2, targetValue: 10)
		let timestamp = Date(timeIntervalSinceReferenceDate: 456)

		let didChange = progress.update(by: 3.5, timestamp: timestamp)

		let event = try #require(progress.events.last)
		#expect(didChange)
		#expect(progress.currentValue == 5.5)
		#expect(event.delta == 3.5)
		#expect(event.timestamp == timestamp)
	}

	@Test
	func `Custom update decreases current value by amount`() throws {
		var progress = makeProgress(currentValue: 6, targetValue: 10)
		let timestamp = Date(timeIntervalSinceReferenceDate: 456)

		let didChange = progress.update(by: -2.5, timestamp: timestamp)

		let event = try #require(progress.events.last)
		#expect(didChange)
		#expect(progress.currentValue == 3.5)
		#expect(event.delta == -2.5)
		#expect(event.timestamp == timestamp)
	}

	@Test
	func `Custom update clamps at target value`() throws {
		var progress = makeProgress(currentValue: 2, targetValue: 10)

		let didChange = progress.update(by: 100)

		let event = try #require(progress.events.last)
		#expect(didChange)
		#expect(progress.currentValue == 10)
		#expect(event.delta == 8)
	}

	@Test
	func `Custom update clamps at zero`() throws {
		var progress = makeProgress(currentValue: 2, targetValue: 10)

		let didChange = progress.update(by: -100)

		let event = try #require(progress.events.last)
		#expect(didChange)
		#expect(progress.currentValue == 0)
		#expect(event.delta == -2)
	}

	@Test
	func `Custom update ignores zero and non-finite amounts`() {
		var progress = makeProgress(currentValue: 2, targetValue: 10)

		let zeroChanged = progress.update(by: 0)
		let infinityChanged = progress.update(by: .infinity)
		let negativeInfinityChanged = progress.update(by: -.infinity)
		let nanChanged = progress.update(by: .nan)

		#expect(zeroChanged == false)
		#expect(infinityChanged == false)
		#expect(negativeInfinityChanged == false)
		#expect(nanChanged == false)
		#expect(progress.currentValue == 2)
		#expect(progress.events.map(\.delta) == [2])
	}

	@Test
	func `Progress methods report false when already at bounds`() {
		var progress = makeProgress(currentValue: 0, targetValue: 10, step: 5)

		let resetAtZeroChanged = progress.reset()
		let decrementAtZeroChanged = progress.decrement()
		progress.complete()
		let completeAtTargetChanged = progress.complete()
		let incrementAtTargetChanged = progress.increment()

		#expect(resetAtZeroChanged == false)
		#expect(decrementAtZeroChanged == false)
		#expect(completeAtTargetChanged == false)
		#expect(incrementAtTargetChanged == false)
	}

	@Test
	func `Deleting a valid event removes only that event`() throws {
		let deletedEventID = UUID()
		let progress = measurableProgress(
			events: [
				GoalProgressEvent(delta: 4, timestamp: Date(timeIntervalSinceReferenceDate: 1)),
				GoalProgressEvent(id: deletedEventID, delta: 2, timestamp: Date(timeIntervalSinceReferenceDate: 2)),
				GoalProgressEvent(delta: 3, timestamp: Date(timeIntervalSinceReferenceDate: 3))
			],
			targetValue: 10,
		)

		let updatedProgress = try #require(progress.deletingEvent(id: deletedEventID))

		#expect(updatedProgress.events.map(\.delta) == [4, 3])
		#expect(
			updatedProgress.events.map(\.timestamp) == [
				Date(timeIntervalSinceReferenceDate: 1),
				Date(timeIntervalSinceReferenceDate: 3)
			]
		)
		#expect(updatedProgress.currentValue == 7)
	}

	@Test
	func `Deleting an out of range event returns nil`() {
		let progress = makeProgress(currentValue: 4, targetValue: 10)

		#expect(progress.deletingEvent(id: UUID()) == nil)
	}

	@Test
	func `Deleting an event that leaves negative progress returns nil`() {
		let deletedEventID = UUID()
		let progress = measurableProgress(
			events: [
				GoalProgressEvent(id: deletedEventID, delta: 10, timestamp: Date(timeIntervalSinceReferenceDate: 1)),
				GoalProgressEvent(delta: -3, timestamp: Date(timeIntervalSinceReferenceDate: 2))
			],
			targetValue: 10,
		)

		#expect(progress.deletingEvent(id: deletedEventID) == nil)
	}

	@Test
	func `Deleting the only positive event returns empty valid history`() throws {
		let progress = makeProgress(currentValue: 4, targetValue: 10)
		let event = try #require(progress.events.first)

		let updatedProgress = try #require(progress.deletingEvent(id: event.id))

		#expect(updatedProgress.events.isEmpty)
		#expect(updatedProgress.currentValue == 0)
	}

	@Test
	func `Deleting multiple valid events removes only those events`() throws {
		let firstDeletedEventID = UUID()
		let secondDeletedEventID = UUID()
		let progress = measurableProgress(
			events: [
				GoalProgressEvent(id: firstDeletedEventID, delta: 4, timestamp: Date(timeIntervalSinceReferenceDate: 1)),
				GoalProgressEvent(delta: 2, timestamp: Date(timeIntervalSinceReferenceDate: 2)),
				GoalProgressEvent(id: secondDeletedEventID, delta: 3, timestamp: Date(timeIntervalSinceReferenceDate: 3))
			],
			targetValue: 10,
		)

		let updatedProgress = try #require(
			progress.deletingEvents(ids: [firstDeletedEventID, secondDeletedEventID])
		)

		#expect(updatedProgress.events.map(\.delta) == [2])
		#expect(
			updatedProgress.events.map(\.timestamp) == [
				Date(timeIntervalSinceReferenceDate: 2)
			]
		)
		#expect(updatedProgress.currentValue == 2)
	}

	@Test
	func `Deleting events with an empty id set returns nil`() {
		let progress = makeProgress(currentValue: 4, targetValue: 10)

		#expect(progress.deletingEvents(ids: []) == nil)
	}

	@Test
	func `Deleting events with no matching ids returns nil`() {
		let progress = makeProgress(currentValue: 4, targetValue: 10)

		#expect(progress.deletingEvents(ids: [UUID()]) == nil)
	}

	@Test
	func `Deleting multiple events that leave negative progress returns nil`() {
		let firstDeletedEventID = UUID()
		let secondDeletedEventID = UUID()
		let progress = measurableProgress(
			events: [
				GoalProgressEvent(id: firstDeletedEventID, delta: 10, timestamp: Date(timeIntervalSinceReferenceDate: 1)),
				GoalProgressEvent(id: secondDeletedEventID, delta: 2, timestamp: Date(timeIntervalSinceReferenceDate: 2)),
				GoalProgressEvent(delta: -3, timestamp: Date(timeIntervalSinceReferenceDate: 3))
			],
			targetValue: 10,
		)

		#expect(progress.deletingEvents(ids: [firstDeletedEventID, secondDeletedEventID]) == nil)
	}

	@Test
	func `Deleting all positive events returns empty valid history`() throws {
		let firstDeletedEventID = UUID()
		let secondDeletedEventID = UUID()
		let progress = measurableProgress(
			events: [
				GoalProgressEvent(id: firstDeletedEventID, delta: 4, timestamp: Date(timeIntervalSinceReferenceDate: 1)),
				GoalProgressEvent(id: secondDeletedEventID, delta: 2, timestamp: Date(timeIntervalSinceReferenceDate: 2))
			],
			targetValue: 10,
		)

		let updatedProgress = try #require(
			progress.deletingEvents(ids: [firstDeletedEventID, secondDeletedEventID])
		)

		#expect(updatedProgress.events.isEmpty)
		#expect(updatedProgress.currentValue == 0)
	}

	// MARK: - Derived State

	@Test
	func `isCompleted is true when current value reaches target`() {
		#expect(makeProgress(currentValue: 9.5, targetValue: 10).isCompleted == false)
		#expect(makeProgress(currentValue: 10, targetValue: 10).isCompleted == true)
	}

	// MARK: - Period Progress

	@Test
	func `Period progress ignores events outside period`() {
		let period = DateInterval(
			start: Date(timeIntervalSinceReferenceDate: 100),
			end: Date(timeIntervalSinceReferenceDate: 200),
		)
		let progress = measurableProgress(
			events: [
				GoalProgressEvent(delta: 10, timestamp: Date(timeIntervalSinceReferenceDate: 50)),
				GoalProgressEvent(delta: 4, timestamp: Date(timeIntervalSinceReferenceDate: 150)),
				GoalProgressEvent(delta: 6, timestamp: Date(timeIntervalSinceReferenceDate: 200))
			],
			targetValue: 10,
			step: 2,
		)

		#expect(progress.currentValue(in: period) == 4)
		#expect(progress.isCompleted(in: period) == false)
	}

	@Test
	func `Period completion uses only current period target progress`() {
		let period = DateInterval(
			start: Date(timeIntervalSinceReferenceDate: 100),
			end: Date(timeIntervalSinceReferenceDate: 200),
		)
		let progress = measurableProgress(
			events: [
				GoalProgressEvent(delta: 10, timestamp: Date(timeIntervalSinceReferenceDate: 50)),
				GoalProgressEvent(delta: 10, timestamp: Date(timeIntervalSinceReferenceDate: 150))
			],
			targetValue: 10,
			step: 2,
		)

		#expect(progress.currentValue(in: period) == 10)
		#expect(progress.isCompleted(in: period) == true)
	}

	@Test
	func `Completing period appends event without clearing prior history`() throws {
		let period = DateInterval(
			start: Date(timeIntervalSinceReferenceDate: 100),
			end: Date(timeIntervalSinceReferenceDate: 200),
		)
		let timestamp = Date(timeIntervalSinceReferenceDate: 150)
		var progress = measurableProgress(
			events: [
				GoalProgressEvent(delta: 10, timestamp: Date(timeIntervalSinceReferenceDate: 50))
			],
			targetValue: 10,
			step: 2,
		)

		let didChange = progress.complete(in: period, timestamp: timestamp)
		let event = try #require(progress.events.last)

		#expect(didChange)
		#expect(progress.events.count == 2)
		#expect(event.delta == 10)
		#expect(event.timestamp == timestamp)
		#expect(progress.currentValue(in: period) == 10)
	}

	@Test
	func `Period increment and decrement mutate current period value`() {
		let period = DateInterval(
			start: Date(timeIntervalSinceReferenceDate: 100),
			end: Date(timeIntervalSinceReferenceDate: 200),
		)
		var progress = measurableProgress(
			events: [
				GoalProgressEvent(delta: 10, timestamp: Date(timeIntervalSinceReferenceDate: 50))
			],
			targetValue: 10,
			step: 2,
		)

		let didIncrement = progress.increment(
			in: period,
			timestamp: Date(timeIntervalSinceReferenceDate: 150),
		)
		let didDecrement = progress.decrement(
			in: period,
			timestamp: Date(timeIntervalSinceReferenceDate: 160),
		)

		#expect(didIncrement == true)
		#expect(didDecrement == true)
		#expect(progress.events.map(\.delta) == [10, 2, -2])
		#expect(progress.currentValue(in: period) == 0)
	}

	@Test
	func `Period custom update mutates current period value`() throws {
		let period = DateInterval(
			start: Date(timeIntervalSinceReferenceDate: 100),
			end: Date(timeIntervalSinceReferenceDate: 200),
		)
		let timestamp = Date(timeIntervalSinceReferenceDate: 150)
		var progress = measurableProgress(
			events: [
				GoalProgressEvent(delta: 10, timestamp: Date(timeIntervalSinceReferenceDate: 50)),
				GoalProgressEvent(delta: 4, timestamp: Date(timeIntervalSinceReferenceDate: 125))
			],
			targetValue: 10,
			step: 2,
		)

		let didChange = progress.update(by: 3, in: period, timestamp: timestamp)

		let event = try #require(progress.events.last)
		#expect(didChange)
		#expect(progress.events.map(\.delta) == [10, 4, 3])
		#expect(progress.currentValue(in: period) == 7)
		#expect(event.timestamp == timestamp)
	}

	// MARK: - Codable

	@Test
	func `Invalid negative progress values throw a data corrupted error`() {
		#expect(throws: DecodingError.self) {
			try decodeMeasurableProgress(
				"""
				{
				    "events": [
				        {
				            "id": "00000000-0000-0000-0000-000000000001",
				            "delta": -1,
				            "timestamp": 0
				        }
				    ],
				    "targetValue": 10,
				    "step": 1
				}
				""",
			)
		}
	}

	@Test
	func `Historical progress may exceed one target value`() throws {
		let progress = try decodeMeasurableProgress(
			"""
			{
				    "events": [
				        {
				            "id": "00000000-0000-0000-0000-000000000001",
				            "delta": 10,
				            "timestamp": 0
				        },
				        {
				            "id": "00000000-0000-0000-0000-000000000002",
				            "delta": 10,
				            "timestamp": 100
				        }
			    ],
			    "targetValue": 10,
			    "step": 1
			}
			""",
		)

		#expect(progress.events.map(\.delta) == [10, 10])
		#expect(progress.currentValue == 10)
	}

	@Test
	func `Missing step decodes with default of one`() throws {
		let progress = try decodeMeasurableProgress(
			"""
			{
				    "events": [
				        {
				            "id": "00000000-0000-0000-0000-000000000001",
				            "delta": 4,
				            "timestamp": 0
				        }
			    ],
			    "targetValue": 10
			}
			""",
		)

		#expect(progress.step == 1)
	}

	@Test
	func `Progress encodes unit storage as a nested value`() throws {
		let progress = GoalProgress.measurable(
			currentValue: 1,
			targetValue: 5,
			unit: .minutes,
		)
		let data = try JSONEncoder().encode(progress)
		let json = try #require(String(data: data, encoding: .utf8))

		#expect(json.contains(#""unitStorage":{"#))
		#expect(json.contains(#""id":"time.minutes""#))
	}

	@Test
	func `Progress encodes empty unit storage when unit is nil`() throws {
		let progress = GoalProgress.measurable(
			currentValue: 1,
			targetValue: 5,
			unit: nil,
		)
		let data = try JSONEncoder().encode(progress)
		let json = try #require(String(data: data, encoding: .utf8))

		#expect(json.contains(#""unitStorage":{}"#))
	}

	@Test
	func `Progress decodes nested preset unit storage`() throws {
		let progress = try decodeMeasurableProgress(
			"""
			{
				    "events": [
				        {
				            "id": "00000000-0000-0000-0000-000000000001",
				            "delta": 1,
				            "timestamp": 0
				        }
			    ],
			    "targetValue": 5,
			    "step": 1,
			    "unitStorage": {
			        "id": "time.minutes"
			    }
			}
			"""
		)

		#expect(progress.unit == .minutes)
	}

	@Test
	func `Progress decodes nested custom unit storage`() throws {
		let progress = try decodeMeasurableProgress(
			"""
			{
				    "events": [
				        {
				            "id": "00000000-0000-0000-0000-000000000001",
				            "delta": 1,
				            "timestamp": 0
				        }
			    ],
			    "targetValue": 5,
			    "step": 1,
			    "unitStorage": {
			        "id": "custom.pages",
			        "category": "custom",
			        "title": "Pages",
			        "abbreviatedTitle": "pg",
			        "suffix": "pg"
			    }
			}
			"""
		)

		#expect(progress.unit?.id == "custom.pages")
		#expect(progress.unit?.title == "Pages")
		#expect(progress.unit?.suffix == "pg")
	}

	@Test
	func `Progress ignores unit storage without id`() throws {
		let progress = try decodeMeasurableProgress(
			"""
			{
				    "events": [
				        {
				            "id": "00000000-0000-0000-0000-000000000001",
				            "delta": 1,
				            "timestamp": 0
				        }
			    ],
			    "targetValue": 5,
			    "step": 1,
			    "unitStorage": {}
			}
			"""
		)

		#expect(progress.unit == nil)
	}

	@Test
	func `Legacy current value payload does not decode`() {
		#expect(throws: DecodingError.self) {
			try decodeMeasurableProgress(
				"""
				{
				    "currentValue": 4,
				    "targetValue": 10,
				    "step": 1
				}
				""",
			)
		}
	}

	private func makeProgress(
		currentValue: Double,
		targetValue: Double,
		step: Double = 1,
		timestamp: Date = Date(timeIntervalSinceReferenceDate: 0),
	) -> MeasurableProgress {
		MeasurableProgress(
			currentValue: currentValue,
			targetValue: targetValue,
			step: step,
			timestamp: timestamp,
		)
	}

	private func measurableProgress(
		events: [GoalProgressEvent],
		targetValue: Double,
		step: Double = 1,
		unit: GoalProgressUnit? = nil,
	) -> MeasurableProgress {
		MeasurableProgress(
			events: events,
			targetValue: targetValue,
			step: step,
			unit: unit,
		)
	}

	private func decodeMeasurableProgress(_ json: String) throws -> MeasurableProgress {
		let data = try #require(json.data(using: .utf8))
		return try JSONDecoder().decode(MeasurableProgress.self, from: data)
	}
}
