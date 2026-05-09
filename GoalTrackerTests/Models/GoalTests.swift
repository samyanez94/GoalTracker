//
//  GoalTests.swift
//  GoalTrackerTests
//
//  Created by Codex on 5/9/26.
//

@testable import GoalTracker
import Foundation
import Testing

struct GoalTests {
    @Test func outcomeCompletionTogglesBetweenPendingAndCompleted() {
        var goal = Goal(
            name: "File taxes",
            description: nil,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            completion: .outcome(isCompleted: false),
        )

        #expect(goal.isCompleted == false)
        #expect(goal.complete() == true)
        #expect(goal.isCompleted == true)
        #expect(goal.complete() == false)
        #expect(goal.toggleCompletion() == true)
        #expect(goal.isCompleted == false)
    }

    @Test func progressCompletionReflectsCurrentValueAgainstTarget() {
        var goal = Goal(
            name: "Run 10 miles",
            description: nil,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            completion: .progress(
                Goal.Progress(
                    currentValue: 4,
                    targetValue: 10,
                    incrementValue: 3,
                ),
            ),
        )

        #expect(goal.isCompleted == false)
        #expect(goal.completion.fractionCompleted == 0.4)

        #expect(goal.incrementProgress() == true)
        #expect(goal.completion.fractionCompleted == 0.7)
        #expect(goal.isCompleted == false)

        #expect(goal.complete() == true)
        #expect(goal.isCompleted == true)
        #expect(goal.completion.fractionCompleted == 1)
    }

    @Test func decrementProgressUpdatesProgressGoal() {
        var goal = Goal(
            name: "Read 10 books",
            description: nil,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            completion: .progress(
                Goal.Progress(
                    currentValue: 6,
                    targetValue: 10,
                    incrementValue: 2,
                ),
            ),
        )

        #expect(goal.decrementProgress() == true)
        #expect(goal.completion.fractionCompleted == 0.4)

        #expect(goal.decrementProgress() == true)
        #expect(goal.completion.fractionCompleted == 0.2)
    }

    @Test func progressIncrementAndDecrementClampToBounds() {
        var progress = Goal.Progress(
            currentValue: 9,
            targetValue: 10,
            incrementValue: 4,
        )

        #expect(progress.canIncrement == true)
        #expect(progress.increment() == true)
        #expect(progress.currentValue == 10)
        #expect(progress.canIncrement == false)
        #expect(progress.increment() == false)
        #expect(progress.currentValue == 10)

        #expect(progress.decrement() == true)
        #expect(progress.currentValue == 6)

        #expect(progress.reset() == true)
        #expect(progress.currentValue == 0)
        #expect(progress.canDecrement == false)
        #expect(progress.decrement() == false)
        #expect(progress.currentValue == 0)
    }

    @Test func progressSupportsFractionalStepValues() {
        var progress = Goal.Progress(
            currentValue: 0,
            targetValue: 2,
            incrementValue: 0.5,
        )

        #expect(progress.increment() == true)
        #expect(progress.currentValue == 0.5)

        #expect(progress.increment() == true)
        #expect(progress.currentValue == 1)
    }

    @Test func progressValidationRejectsInvalidValues() {
        #expect(
            Goal.Progress.isValid(
                currentValue: -1,
                targetValue: 10,
                incrementValue: 1,
            ) == false,
        )
        #expect(
            Goal.Progress.isValid(
                currentValue: 1,
                targetValue: 0,
                incrementValue: 1,
            ) == false,
        )
        #expect(
            Goal.Progress.isValid(
                currentValue: 11,
                targetValue: 10,
                incrementValue: 1,
            ) == false,
        )
        #expect(
            Goal.Progress.isValid(
                currentValue: 1,
                targetValue: 10,
                incrementValue: .infinity,
            ) == false,
        )
    }

    @MainActor
    @Test func decodingProgressRejectsInvalidPersistedValues() throws {
        let data = """
        {
            "currentValue": 5,
            "targetValue": 0,
            "incrementValue": 1
        }
        """.data(using: .utf8)!

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Goal.Progress.self, from: data)
        }
    }
}
