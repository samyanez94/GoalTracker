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
        #expect(didChange)
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
        #expect(didChange)
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
        #expect(didChange)
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
    func `Invalid progress values throw a data corrupted error`() {
        #expect(throws: DecodingError.self) {
            try decodeProgress(
                """
                {
                    "kind": "measurable",
                    "events": [
                        {
                            "delta": 11,
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
