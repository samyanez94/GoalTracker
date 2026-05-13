//
//  GoalTests.swift
//  GoalTrackerTests
//
//  Created by Codex on 5/9/26.
//

import Foundation
import Testing

@testable import GoalTracker

// MARK: - GoalTests

@MainActor
@Suite
struct GoalTests {

  // MARK: - GoalProgressTests

  @MainActor
  struct GoalProgressTests {
    @Test
    func `Complete sets current value to target`() {
      var progress = makeProgress(currentValue: 3, targetValue: 10)

      let didChange = progress.complete()

      #expect(didChange)
      #expect(progress.currentValue == 10)
    }

    @Test
    func `Reset sets current value to zero`() {
      var progress = makeProgress(currentValue: 3, targetValue: 10)

      let didChange = progress.reset()

      #expect(didChange)
      #expect(progress.currentValue == 0)
    }

    @Test
    func `Increment increases current value by step`() {
      var progress = makeProgress(currentValue: 2, targetValue: 10, step: 2.5)

      let didChange = progress.increment()

      #expect(didChange)
      #expect(progress.currentValue == 4.5)
    }

    @Test
    func `Decrement decreases current value by step`() {
      var progress = makeProgress(currentValue: 6, targetValue: 10, step: 2.5)

      let didChange = progress.decrement()

      #expect(didChange)
      #expect(progress.currentValue == 3.5)
    }

    @Test
    func `Increment clamps at target value`() {
      var progress = makeProgress(currentValue: 8, targetValue: 10, step: 5)

      let didChange = progress.increment()

      #expect(didChange)
      #expect(progress.currentValue == 10)
    }

    @Test
    func `Decrement clamps at zero`() {
      var progress = makeProgress(currentValue: 2, targetValue: 10, step: 5)

      let didChange = progress.decrement()

      #expect(didChange)
      #expect(progress.currentValue == 0)
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

  // MARK: - GoalCompletionTests

  @MainActor
  struct GoalCompletionTests {
    @Test
    func `Outcome completion can complete, mark pending, and toggle`() {
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

    @Test
    func `Progress completion delegates complete and reset`() {
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

    @Test
    func `Progress completion delegates increment and decrement`() {
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

    @Test
    func `Progress changes return false for outcome goals`() {
      var completion = Goal.Completion.outcome(isCompleted: false)

      let incrementChanged = completion.incrementProgress()
      let decrementChanged = completion.decrementProgress()

      #expect(incrementChanged == false)
      #expect(decrementChanged == false)
    }

    @Test
    func `Outcome fractionCompleted returns one or zero`() {
      #expect(Goal.Completion.outcome(isCompleted: false).fractionCompleted == 0)
      #expect(Goal.Completion.outcome(isCompleted: true).fractionCompleted == 1)
    }
  }

  // MARK: - GoalModelTests

  @MainActor
  struct GoalModelTests {
    @Test
    func `Goal isCompleted delegates to completion`() {
      #expect(makeGoal(completion: .outcome(isCompleted: false)).isCompleted == false)
      #expect(makeGoal(completion: .outcome(isCompleted: true)).isCompleted == true)
    }

    @Test
    func `Goal complete delegates to completion and updates state`() {
      var goal = makeGoal(completion: .outcome(isCompleted: false))

      let didChange = goal.complete()

      #expect(didChange)
      #expect(goal.isCompleted)
    }

    @Test
    func `Goal markPending delegates to completion and updates state`() {
      var goal = makeGoal(completion: .outcome(isCompleted: true))

      let didChange = goal.markPending()

      #expect(didChange)
      #expect(goal.isCompleted == false)
    }

    @Test
    func `Goal toggleCompletion delegates to completion and updates state`() {
      var goal = makeGoal(completion: .outcome(isCompleted: false))

      let firstToggleChanged = goal.toggleCompletion()

      #expect(firstToggleChanged)
      #expect(goal.isCompleted)

      let secondToggleChanged = goal.toggleCompletion()

      #expect(secondToggleChanged)
      #expect(goal.isCompleted == false)
    }

    @Test
    func `Goal progress changes delegate to completion and update state`() {
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

  // MARK: - GoalCodableTests

  @MainActor
  struct GoalCodableTests {
    @Test
    func `Valid progress values decode successfully`() throws {
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

    @Test
    func `Invalid progress values throw a data corrupted error`() {
      do {
        _ = try decodeProgress(
          """
          {
              "currentValue": 11,
              "targetValue": 10,
              "step": 1
          }
          """,
        )
        Issue.record("Expected invalid progress values to throw.")
      } catch DecodingError.dataCorrupted {
        // Expected.
      } catch {
        Issue.record("Expected dataCorrupted, got \(error).")
      }
    }

    @Test
    func `Missing step decodes with default of one`() throws {
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

}
