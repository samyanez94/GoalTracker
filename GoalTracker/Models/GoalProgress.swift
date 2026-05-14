//
//  GoalProgress.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation

/// Tracks the state used to determine whether a goal is complete.
nonisolated struct GoalProgress: Codable {
  /// Whether this progress represents a binary outcome or a measurable target.
  private(set) var kind: GoalProgressKind
  /// The user's current progress toward the target value.
  private(set) var currentValue: Double
  /// The value at which the goal is considered complete.
  private(set) var targetValue: Double
  /// The amount used when stepping measurable progress up or down.
  private(set) var step: Double
  /// The optional unit used when displaying measurable progress values.
  private(set) var unit: GoalProgressUnit?

  static let outcomePending = GoalProgress(
    kind: .outcome,
    currentValue: 0,
    targetValue: 1,
    step: 1,
    unit: nil,
  )

  static let outcomeCompleted = GoalProgress(
    kind: .outcome,
    currentValue: 1,
    targetValue: 1,
    step: 1,
    unit: nil,
  )

  /// Whether the current value has reached or exceeded the target value.
  var isCompleted: Bool {
    currentValue >= targetValue
  }

  var isMeasurable: Bool {
    kind == .measurable
  }

  var canDecrement: Bool {
    isMeasurable && currentValue > 0
  }

  var canIncrement: Bool {
    isMeasurable && currentValue < upperBound
  }

  /// The progress amount represented from 0 to 1.
  var fractionCompleted: Double {
    guard targetValue > 0 else {
      return isCompleted ? 1 : 0
    }
    return currentValue / targetValue
  }

  init(
    kind: GoalProgressKind,
    currentValue: Double,
    targetValue: Double,
    step: Double = 1,
    unit: GoalProgressUnit? = nil,
  ) {
    precondition(
      Self.isValid(
        currentValue: currentValue,
        targetValue: targetValue,
        step: step,
      ),
      "Progress values must be finite, non-negative, and within target bounds.",
    )
    self.kind = kind
    self.currentValue = currentValue
    self.targetValue = targetValue
    self.step = step
    self.unit = unit
  }

  init(
    currentValue: Double,
    targetValue: Double,
    step: Double = 1,
    unit: GoalProgressUnit? = nil,
  ) {
    self.init(
      kind: .measurable,
      currentValue: currentValue,
      targetValue: targetValue,
      step: step,
      unit: unit,
    )
  }

  static func measurable(
    currentValue: Double,
    targetValue: Double,
    step: Double = 1,
    unit: GoalProgressUnit? = nil,
  ) -> GoalProgress {
    GoalProgress(
      kind: .measurable,
      currentValue: currentValue,
      targetValue: targetValue,
      step: step,
      unit: unit,
    )
  }

  static func isValid(
    currentValue: Double,
    targetValue: Double,
    step: Double,
  ) -> Bool {
    currentValue.isFinite
      && targetValue.isFinite
      && step.isFinite
      && currentValue >= 0
      && targetValue > 0
      && step > 0
      && currentValue <= targetValue
  }

  @discardableResult
  mutating func complete() -> Bool {
    setCurrentValue(targetValue)
  }

  @discardableResult
  mutating func reset() -> Bool {
    setCurrentValue(0)
  }

  @discardableResult
  mutating func markPending() -> Bool {
    reset()
  }

  @discardableResult
  mutating func toggleCompletion() -> Bool {
    isCompleted ? reset() : complete()
  }

  @discardableResult
  mutating func increment() -> Bool {
    guard isMeasurable else {
      return false
    }
    return setCurrentValue(currentValue + step)
  }

  @discardableResult
  mutating func incrementProgress() -> Bool {
    increment()
  }

  @discardableResult
  mutating func decrement() -> Bool {
    guard isMeasurable else {
      return false
    }
    return setCurrentValue(currentValue - step)
  }

  @discardableResult
  mutating func decrementProgress() -> Bool {
    decrement()
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let kind = try container.decode(GoalProgressKind.self, forKey: .kind)
    let currentValue = try container.decode(Double.self, forKey: .currentValue)
    let targetValue = try container.decode(Double.self, forKey: .targetValue)
    let step = try container.decodeIfPresent(Double.self, forKey: .step) ?? 1
    let unit = try container.decodeIfPresent(GoalProgressUnit.self, forKey: .unit)
    guard
      Self.isValid(
        currentValue: currentValue,
        targetValue: targetValue,
        step: step,
      )
    else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription:
            "Progress values must be finite, non-negative, and within target bounds.",
        ),
      )
    }
    self.kind = kind
    self.currentValue = currentValue
    self.targetValue = targetValue
    self.step = step
    self.unit = unit
  }

  private var upperBound: Double {
    max(0, targetValue)
  }

  @discardableResult
  private mutating func setCurrentValue(_ value: Double) -> Bool {
    let updatedValue = min(max(0, value), upperBound)
    guard currentValue != updatedValue else {
      return false
    }
    currentValue = updatedValue
    return true
  }
}
