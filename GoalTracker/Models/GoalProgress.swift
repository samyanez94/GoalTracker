//
//  GoalProgress.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation

/// Stores the current progress summary for a goal.
///
/// `GoalProgress` is the source of truth for where a goal stands right now.
///
/// `GoalProgressEntry` records dated changes over time for future charts and
/// calendars.
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
        let storage = try GoalProgressStorage(from: decoder)
        guard
            Self.isValid(
                currentValue: storage.currentValue,
                targetValue: storage.targetValue,
                step: storage.step,
            )
        else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription:
                        "Progress values must be finite, non-negative, and within target bounds.",
                ),
            )
        }
        kind = storage.kind
        currentValue = storage.currentValue
        targetValue = storage.targetValue
        step = storage.step
        unit = storage.unit?.resolvedUnit()
    }

    func encode(to encoder: Encoder) throws {
        try GoalProgressStorage(
            kind: kind,
            currentValue: currentValue,
            targetValue: targetValue,
            step: step,
            unit: unit,
        )
        .encode(to: encoder)
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

nonisolated private struct GoalProgressStorage: Codable {
    var kind: GoalProgressKind
    var currentValue: Double
    var targetValue: Double
    var step: Double
    var unit: GoalProgressUnitSnapshot?

    private enum CodingKeys: String, CodingKey {
        case kind
        case currentValue
        case targetValue
        case step
        case unit
    }

    init(
        kind: GoalProgressKind,
        currentValue: Double,
        targetValue: Double,
        step: Double,
        unit: GoalProgressUnit?,
    ) {
        self.kind = kind
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.step = step
        self.unit = unit.map(GoalProgressUnitSnapshot.init)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decode(GoalProgressKind.self, forKey: .kind)
        currentValue = try container.decode(Double.self, forKey: .currentValue)
        targetValue = try container.decode(Double.self, forKey: .targetValue)
        step = try container.decodeIfPresent(Double.self, forKey: .step) ?? 1
        unit = try container.decodeIfPresent(GoalProgressUnitSnapshot.self, forKey: .unit)
    }
}

nonisolated private struct GoalProgressUnitSnapshot: Codable {
    var id: String?
    var category: GoalProgressUnit.Category?
    var title: String?
    var abbreviatedTitle: String?
    var prefix: String?
    var suffix: String?

    init(_ unit: GoalProgressUnit) {
        id = unit.id
        category = unit.category
        title = unit.title
        abbreviatedTitle = unit.abbreviatedTitle
        prefix = unit.prefix
        suffix = unit.suffix
    }

    func resolvedUnit() -> GoalProgressUnit? {
        guard let id else {
            return nil
        }
        if let preset = GoalProgressUnit.preset(withID: id) {
            return preset
        }
        let fallbackTitle = title ?? abbreviatedTitle ?? id
        return GoalProgressUnit(
            id: id,
            category: category ?? .custom,
            title: fallbackTitle,
            abbreviatedTitle: abbreviatedTitle ?? fallbackTitle,
            prefix: prefix,
            suffix: suffix,
        )
    }
}
