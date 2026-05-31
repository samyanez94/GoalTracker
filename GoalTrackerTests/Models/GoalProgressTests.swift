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
    func `Progress methods report whether state changed`() {
        var progress = makeProgress(currentValue: 0, targetValue: 10, step: 5)

        let resetAtZeroChanged = progress.reset()
        let decrementAtZeroChanged = progress.decrement()
        let incrementChanged = progress.increment()
        let completeChanged = progress.complete()
        let completeAtTargetChanged = progress.complete()
        let incrementAtTargetChanged = progress.increment()

        #expect(resetAtZeroChanged == false)
        #expect(decrementAtZeroChanged == false)
        #expect(incrementChanged == true)
        #expect(completeChanged == true)
        #expect(completeAtTargetChanged == false)
        #expect(incrementAtTargetChanged == false)
    }

    @Test
    func `isCompleted is true when current value reaches target`() {
        #expect(makeProgress(currentValue: 9.5, targetValue: 10).isCompleted == false)
        #expect(makeProgress(currentValue: 10, targetValue: 10).isCompleted == true)
    }

    @Test
    func `Period progress ignores events outside period`() {
        let period = DateInterval(
            start: Date(timeIntervalSinceReferenceDate: 100),
            end: Date(timeIntervalSinceReferenceDate: 200),
        )
        let progress = GoalProgress(
            kind: .measurable,
            events: [
                GoalProgressEvent(delta: 10, timestamp: Date(timeIntervalSinceReferenceDate: 50)),
                GoalProgressEvent(delta: 4, timestamp: Date(timeIntervalSinceReferenceDate: 150)),
                GoalProgressEvent(delta: 6, timestamp: Date(timeIntervalSinceReferenceDate: 200)),
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
        let progress = GoalProgress(
            kind: .measurable,
            events: [
                GoalProgressEvent(delta: 10, timestamp: Date(timeIntervalSinceReferenceDate: 50)),
                GoalProgressEvent(delta: 10, timestamp: Date(timeIntervalSinceReferenceDate: 150)),
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
        var progress = GoalProgress(
            kind: .measurable,
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
        var progress = GoalProgress(
            kind: .measurable,
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
        var progress = GoalProgress(
            kind: .measurable,
            events: [
                GoalProgressEvent(delta: 10, timestamp: Date(timeIntervalSinceReferenceDate: 50)),
                GoalProgressEvent(delta: 4, timestamp: Date(timeIntervalSinceReferenceDate: 125)),
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

    @Test
    func `fractionCompleted returns current value divided by target`() {
        let progress = makeProgress(currentValue: 4, targetValue: 10)

        #expect(progress.fractionCompleted == 0.4)
    }

    @Test
    func `Outcome progress acts like zero or one progress`() {
        #expect(GoalProgress.outcomePending.kind == .outcome)
        #expect(GoalProgress.outcomePending.events.isEmpty)
        #expect(GoalProgress.outcomePending.fractionCompleted == 0)
        #expect(GoalProgress.outcomeCompleted.fractionCompleted == 1)
    }

    @Test
    func `Outcome progress does not step incrementally`() {
        var progress = GoalProgress.outcomePending

        let didIncrement = progress.increment()
        let didDecrement = progress.decrement()

        #expect(didIncrement == false)
        #expect(didDecrement == false)
        #expect(progress.currentValue == 0)
        #expect(progress.events.isEmpty)
    }

    @Test
    func `Updated progress preserves events when current value is unchanged`() {
        let originalTimestamp = Date(timeIntervalSinceReferenceDate: 123)
        let previousProgress = makeProgress(
            currentValue: 4,
            targetValue: 10,
            step: 2,
            timestamp: originalTimestamp,
        )
        let editedProgress = makeProgress(currentValue: 4, targetValue: 12, step: 3)

        let updatedProgress = editedProgress.updated(
            preservingEventsFrom: previousProgress,
            timestamp: Date(timeIntervalSinceReferenceDate: 456),
        )

        #expect(updatedProgress.currentValue == 4)
        #expect(updatedProgress.targetValue == 12)
        #expect(updatedProgress.step == 3)
        #expect(updatedProgress.events.count == 1)
        #expect(updatedProgress.events.first?.timestamp == originalTimestamp)
    }

    @Test
    func `Updated progress appends balancing event when current value changes`() {
        let previousProgress = makeProgress(currentValue: 4, targetValue: 10)
        let editedProgress = makeProgress(currentValue: 7, targetValue: 10)
        let timestamp = Date(timeIntervalSinceReferenceDate: 456)

        let updatedProgress = editedProgress.updated(
            preservingEventsFrom: previousProgress,
            timestamp: timestamp,
        )

        #expect(updatedProgress.currentValue == 7)
        #expect(updatedProgress.events.map(\.delta) == [4, 3])
        #expect(updatedProgress.events.last?.timestamp == timestamp)
    }

    @Test
    func `Valid progress values decode successfully`() throws {
        let progress = try decodeProgress(
            """
            {
                "kind": "measurable",
                "events": [
                    {
                        "delta": 4,
                        "timestamp": 0
                    }
                ],
                "targetValue": 10,
                "step": 2
            }
            """,
        )

        #expect(progress.kind == .measurable)
        #expect(progress.events.map(\.delta) == [4])
        #expect(progress.currentValue == 4)
        #expect(progress.targetValue == 10)
        #expect(progress.step == 2)
    }

    @Test
    func `Invalid negative progress values throw a data corrupted error`() {
        #expect(throws: DecodingError.self) {
            try decodeProgress(
                """
                {
                    "kind": "measurable",
                    "events": [
                        {
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
        let progress = try decodeProgress(
            """
            {
                "kind": "measurable",
                "events": [
                    {
                        "delta": 10,
                        "timestamp": 0
                    },
                    {
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
        let progress = try decodeProgress(
            """
            {
                "kind": "measurable",
                "events": [
                    {
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
    func `Legacy current value payload does not decode`() {
        #expect(throws: DecodingError.self) {
            try decodeProgress(
                """
                {
                    "kind": "measurable",
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
    ) -> GoalProgress {
        GoalProgress.measurable(
            currentValue: currentValue,
            targetValue: targetValue,
            step: step,
            timestamp: timestamp,
        )
    }

    private func decodeProgress(_ json: String) throws -> GoalProgress {
        let data = try #require(json.data(using: .utf8))
        return try JSONDecoder().decode(GoalProgress.self, from: data)
    }
}
