//
//  GoalProgressTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/14/26.
//

import Testing

@testable import GoalTracker

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

  @Test
  func `Outcome progress acts like zero or one progress`() {
    #expect(GoalProgress.outcomePending.kind == .outcome)
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
  }

  private func makeProgress(
    currentValue: Double,
    targetValue: Double,
    step: Double = 1,
  ) -> GoalProgress {
    GoalProgress.measurable(
      currentValue: currentValue,
      targetValue: targetValue,
      step: step,
    )
  }
}
