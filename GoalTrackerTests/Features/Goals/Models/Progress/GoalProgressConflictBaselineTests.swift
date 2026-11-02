import Foundation
import Testing

@testable import GoalTracker

/// Exercises operations from independent copies of the same history.
/// This is a calculation baseline, not a simulation of CloudKit's merge behavior.
@MainActor
struct GoalProgressConflictBaselineTests {
	@Test(arguments: [false, true])
	func `Independent additions retain both contributions regardless of order`(reverse: Bool) throws {
		let baseline = MeasurableProgress(currentValue: 4, targetValue: 10, timestamp: date(0))
		var firstDevice = baseline
		var secondDevice = baseline
		firstDevice.update(by: 2, timestamp: date(1))
		secondDevice.update(by: 3, timestamp: date(1))
		let first = try #require(firstDevice.events.last)
		let second = try #require(secondDevice.events.last)
		let additions = reverse ? [second, first] : [first, second]
		let merged = MeasurableProgress(events: baseline.events + additions, targetValue: 10)

		#expect(first.id != second.id)
		#expect(merged.currentValue == 9)
		#expect(merged.events.count == 3)
		#expect(Set(merged.events.map(\.id)).count == 3)
	}

	@Test
	func `Concurrent completions retain surplus and the next decrement adjusts the visible value`() throws {
		let baseline = MeasurableProgress(currentValue: 4, targetValue: 10, timestamp: date(0))
		var firstDevice = baseline
		var secondDevice = baseline
		firstDevice.complete(timestamp: date(1))
		secondDevice.complete(timestamp: date(2))
		let additions = [try #require(firstDevice.events.last), try #require(secondDevice.events.last)]
		var merged = MeasurableProgress(events: baseline.events + additions, targetValue: 10)

		#expect(merged.events.map(\.delta) == [4, 6, 6])
		#expect(merged.currentValue == 10)
		merged.decrement(timestamp: date(3))
		#expect(merged.events.last?.delta == -7)
		#expect(merged.currentValue == 9)
	}

	@Test
	func `Reset only cancels the history observed by its author`() throws {
		let baseline = MeasurableProgress(currentValue: 4, targetValue: 10, timestamp: date(0))
		var firstDevice = baseline
		var secondDevice = baseline
		firstDevice.reset(timestamp: date(1))
		secondDevice.update(by: 2, timestamp: date(2))
		let additions = [try #require(firstDevice.events.last), try #require(secondDevice.events.last)]
		let merged = MeasurableProgress(events: baseline.events + additions, targetValue: 10)

		#expect(merged.events.map(\.delta) == [4, -4, 2])
		#expect(merged.currentValue == 2)
	}

	@Test
	func `V1 rejects negative totals produced by independently valid decrements`() throws {
		let baseline = MeasurableProgress(currentValue: 2, targetValue: 10, timestamp: date(0))
		var firstDevice = baseline
		var secondDevice = baseline
		firstDevice.update(by: -2, timestamp: date(1))
		secondDevice.update(by: -2, timestamp: date(2))
		let events = baseline.events + [try #require(firstDevice.events.last), try #require(secondDevice.events.last)]

		#expect(firstDevice.currentValue == 0)
		#expect(secondDevice.currentValue == 0)
		#expect(events.map(\.delta) == [2, -2, -2])
		// A V2 reader must display zero without discarding events. Never feed this to V1's preconditioned initializer.
		#expect(MeasurableProgress.isValid(events: events, targetValue: 10, step: 1) == false)
	}

	@Test
	func `Merged binary completions reset once but cannot round trip through the V1 decoder`() throws {
		var firstDevice = OutcomeProgress()
		var secondDevice = OutcomeProgress()
		firstDevice.complete(timestamp: date(1))
		secondDevice.complete(timestamp: date(2))
		var merged = OutcomeProgress(events: firstDevice.events + secondDevice.events)

		#expect(merged.isCompleted)
		merged.reset(timestamp: date(3))
		#expect(merged.events.map(\.delta) == [1, 1, -2])
		#expect(merged.isCompleted == false)
		#expect(OutcomeProgress.isValid(events: merged.events) == false)
		let encoded = try JSONEncoder().encode(merged)
		#expect(throws: DecodingError.self) {
			try JSONDecoder().decode(OutcomeProgress.self, from: encoded)
		}
	}

	@Test
	func `V1 does not deduplicate repeated event identities`() {
		let event = GoalProgressEvent(delta: 2, timestamp: date(0))
		let progress = MeasurableProgress(events: [event, event], targetValue: 10)

		// Deduplication belongs before calculation in V2; it is not supplied by these value types.
		#expect(progress.currentValue == 4)
		#expect(progress.events.count == 2)
	}

	@Test
	func `Independently allowed deletions can leave a negative combined history`() throws {
		let first = GoalProgressEvent(delta: 4, timestamp: date(0))
		let second = GoalProgressEvent(delta: 4, timestamp: date(1))
		let subtraction = GoalProgressEvent(delta: -3, timestamp: date(2))
		let baseline = MeasurableProgress(events: [first, second, subtraction], targetValue: 10)

		let firstDevice = try #require(baseline.deletingEvent(id: first.id))
		let secondDevice = try #require(baseline.deletingEvent(id: second.id))
		#expect(firstDevice.currentValue == 1)
		#expect(secondDevice.currentValue == 1)
		#expect(MeasurableProgress.isValid(events: [subtraction], targetValue: 10, step: 1) == false)
	}

	private func date(_ seconds: TimeInterval) -> Date {
		Date(timeIntervalSinceReferenceDate: seconds)
	}
}
