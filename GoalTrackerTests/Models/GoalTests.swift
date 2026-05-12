//
//  GoalTests.swift
//  GoalTrackerTests
//
//  Created by Codex on 5/9/26.
//

@testable import GoalTracker
import Foundation
import Testing

@Suite("Goal.Progress tests")
struct GoalProgressTests {
    @Test("Complete sets current value to target")
    func completeSetsCurrentValueToTargetValue() {
        var progress = makeProgress(currentValue: 3, targetValue: 10)

        let didChange = progress.complete()

        #expect(didChange)
        #expect(progress.currentValue == 10)
    }

    @Test("Reset sets current value to zero")
    func resetSetsCurrentValueToZero() {
        var progress = makeProgress(currentValue: 3, targetValue: 10)

        let didChange = progress.reset()

        #expect(didChange)
        #expect(progress.currentValue == 0)
    }

    @Test("Increment increases current value by step")
    func incrementIncreasesCurrentValueByStep() {
        var progress = makeProgress(currentValue: 2, targetValue: 10, step: 2.5)

        let didChange = progress.increment()

        #expect(didChange)
        #expect(progress.currentValue == 4.5)
    }

    @Test("Decrement decreases current value by step")
    func decrementDecreasesCurrentValueByStep() {
        var progress = makeProgress(currentValue: 6, targetValue: 10, step: 2.5)

        let didChange = progress.decrement()

        #expect(didChange)
        #expect(progress.currentValue == 3.5)
    }

    @Test("Increment clamps at target value")
    func incrementClampsAtTargetValue() {
        var progress = makeProgress(currentValue: 8, targetValue: 10, step: 5)

        let didChange = progress.increment()

        #expect(didChange)
        #expect(progress.currentValue == 10)
    }

    @Test("Decrement clamps at zero")
    func decrementClampsAtZero() {
        var progress = makeProgress(currentValue: 2, targetValue: 10, step: 5)

        let didChange = progress.decrement()

        #expect(didChange)
        #expect(progress.currentValue == 0)
    }

    @Test("Progress methods report whether state changed")
    func methodsReturnTrueOnlyWhenStateChanges() {
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

    @Test("isCompleted is true when current value reaches target")
    func isCompletedIsTrueWhenCurrentValueReachesTargetValue() {
        #expect(makeProgress(currentValue: 9.5, targetValue: 10).isCompleted == false)
        #expect(makeProgress(currentValue: 10, targetValue: 10).isCompleted == true)
    }

    @Test("fractionCompleted returns current value divided by target")
    func fractionCompletedReturnsCurrentValueDividedByTargetValue() {
        let progress = makeProgress(currentValue: 4, targetValue: 10)

        #expect(progress.fractionCompleted == 0.4)
    }

    private func makeProgress(
        currentValue: Double,
        targetValue: Double,
        step: Double = 1,
    ) -> Goal.Progress {
        Goal.Progress(
            currentValue: currentValue,
            targetValue: targetValue,
            step: step,
        )
    }
}

@Suite("Goal.Completion tests")
struct GoalCompletionTests {
    @Test("Putcome completion can complete, mark pending, and toggle")
    func outcomeCanBeCompletedMarkedPendingAndToggled() {
        var completion = Goal.Completion.outcome(isCompleted: false)

        let completeChanged = completion.complete()

        #expect(completeChanged)
        #expect(completion.isCompleted)

        let markPendingChanged = completion.markPending()

        #expect(markPendingChanged)
        #expect(completion.isCompleted == false)

        let firstToggleChanged = completion.toggleCompletion()

        #expect(firstToggleChanged)
        #expect(completion.isCompleted)

        let secondToggleChanged = completion.toggleCompletion()

        #expect(secondToggleChanged)
        #expect(completion.isCompleted == false)
    }

    @Test("Progress completion delegates complete and reset")
    func progressCompletionDelegatesCompleteAndReset() {
        var completion = Goal.Completion.progress(
            Goal.Progress(currentValue: 4, targetValue: 10),
        )

        let completeChanged = completion.complete()

        #expect(completeChanged)
        #expect(completion.isCompleted)
        #expect(completion.fractionCompleted == 1)

        let markPendingChanged = completion.markPending()

        #expect(markPendingChanged)
        #expect(completion.isCompleted == false)
        #expect(completion.fractionCompleted == 0)
    }

    @Test("{rogress completion delegates increment and decrement")
    func progressCompletionDelegatesIncrementAndDecrement() {
        var completion = Goal.Completion.progress(
            Goal.Progress(currentValue: 4, targetValue: 10, step: 2),
        )

        let incrementChanged = completion.incrementProgress()

        #expect(incrementChanged)
        #expect(completion.fractionCompleted == 0.6)

        let decrementChanged = completion.decrementProgress()

        #expect(decrementChanged)
        #expect(completion.fractionCompleted == 0.4)
    }

    @Test("Progress changes return false for outcome goals")
    func progressChangesReturnFalseForOutcomeGoals() {
        var completion = Goal.Completion.outcome(isCompleted: false)

        let incrementChanged = completion.incrementProgress()
        let decrementChanged = completion.decrementProgress()

        #expect(incrementChanged == false)
        #expect(decrementChanged == false)
    }

    @Test("outcome fractionCompleted returns one or zero")
    func outcomeFractionCompletedReturnsOneOrZero() {
        #expect(Goal.Completion.outcome(isCompleted: false).fractionCompleted == 0)
        #expect(Goal.Completion.outcome(isCompleted: true).fractionCompleted == 1)
    }
}

@Suite("Goal tests")
struct GoalTests {
    @Test("Goal isCompleted delegates to completion")
    func isCompletedDelegatesToCompletion() {
        #expect(makeGoal(completion: .outcome(isCompleted: false)).isCompleted == false)
        #expect(makeGoal(completion: .outcome(isCompleted: true)).isCompleted == true)
    }

    @Test("Goal complete delegates to completion and updates state")
    func completeDelegatesToCompletionAndUpdatesGoal() {
        var goal = makeGoal(completion: .outcome(isCompleted: false))

        let didChange = goal.complete()

        #expect(didChange)
        #expect(goal.isCompleted)
    }

    @Test("Goal markPending delegates to completion and updates state")
    func markPendingDelegatesToCompletionAndUpdatesGoal() {
        var goal = makeGoal(completion: .outcome(isCompleted: true))

        let didChange = goal.markPending()

        #expect(didChange)
        #expect(goal.isCompleted == false)
    }

    @Test("Goal toggleCompletion delegates to completion and updates state")
    func toggleCompletionDelegatesToCompletionAndUpdatesGoal() {
        var goal = makeGoal(completion: .outcome(isCompleted: false))

        let firstToggleChanged = goal.toggleCompletion()

        #expect(firstToggleChanged)
        #expect(goal.isCompleted)

        let secondToggleChanged = goal.toggleCompletion()

        #expect(secondToggleChanged)
        #expect(goal.isCompleted == false)
    }

    @Test("Goal progress changes delegate to completion and update state")
    func progressChangesDelegateToCompletionAndUpdateGoal() {
        var goal = makeGoal(
            completion: .progress(
                Goal.Progress(currentValue: 4, targetValue: 10, step: 2),
            ),
        )

        let incrementChanged = goal.incrementProgress()

        #expect(incrementChanged)
        #expect(goal.completion.fractionCompleted == 0.6)

        let decrementChanged = goal.decrementProgress()

        #expect(decrementChanged)
        #expect(goal.completion.fractionCompleted == 0.4)
    }

    private func makeGoal(completion: Goal.Completion) -> Goal {
        Goal(
            name: "Test Goal",
            description: nil,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            completion: completion,
        )
    }
}

@MainActor
@Suite("Goal+Codable tests")
struct GoalCodableTests {
    @Test("Valid progress values decode successfully")
    func validProgressValuesDecodeSuccessfully() throws {
        let progress = try decodeProgress(
            """
            {
                "currentValue": 4,
                "targetValue": 10,
                "step": 2
            }
            """,
        )

        #expect(progress.currentValue == 4)
        #expect(progress.targetValue == 10)
        #expect(progress.step == 2)
    }

    @Test("Invalid progress values throw a DecodingError")
    func invalidProgressValuesThrowDecodingError() {
        #expect(throws: DecodingError.self) {
            try decodeProgress(
                """
                {
                    "currentValue": 11,
                    "targetValue": 10,
                    "step": 1
                }
                """,
            )
        }
    }

    @Test("Missing step decodes with default of one")
    func missingStepDecodesWithDefaultValueOfOne() throws {
        let progress = try decodeProgress(
            """
            {
                "currentValue": 4,
                "targetValue": 10
            }
            """,
        )

        #expect(progress.step == 1)
    }

    private func decodeProgress(_ json: String) throws -> Goal.Progress {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(Goal.Progress.self, from: data)
    }
}
