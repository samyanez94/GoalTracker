//
//  Goal.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation

struct Goal: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String?
    let createdAt: Date
    var completion: Completion

    var isCompleted: Bool {
        completion.isCompleted
    }

    @discardableResult
    mutating func complete() -> Bool {
        completion.complete()
    }

    @discardableResult
    mutating func markPending() -> Bool {
        completion.markPending()
    }

    @discardableResult
    mutating func toggleCompletion() -> Bool {
        completion.toggleCompletion()
    }

    @discardableResult
    mutating func incrementProgress() -> Bool {
        completion.incrementProgress()
    }

    @discardableResult
    mutating func decrementProgress() -> Bool {
        completion.decrementProgress()
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String?,
        createdAt: Date,
        completion: Completion,
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.completion = completion
    }

    /// Stores the state that determines how a goal reaches completion.
    enum Completion: Codable {
        /// A goal completed by making measurable progress toward a target value.
        case progress(Progress)
        /// A goal completed by achieving an outcome.
        case outcome(isCompleted: Bool)

        /// Whether the goal has reached its completion condition.
        var isCompleted: Bool {
            switch self {
            case let .progress(progress):
                progress.isCompleted
            case let .outcome(isCompleted):
                isCompleted
            }
        }

        /// The goal's completion amount represented from 0 to 1.
        var fractionCompleted: Double {
            switch self {
            case let .progress(progress):
                progress.fractionCompleted
            case let .outcome(isCompleted):
                isCompleted ? 1 : 0
            }
        }

        @discardableResult
        mutating func complete() -> Bool {
            switch self {
            case var .progress(progress):
                let didChange = progress.complete()
                self = .progress(progress)
                return didChange
            case let .outcome(isCompleted):
                self = .outcome(isCompleted: true)
                return !isCompleted
            }
        }

        @discardableResult
        mutating func markPending() -> Bool {
            switch self {
            case var .progress(progress):
                let didChange = progress.reset()
                self = .progress(progress)
                return didChange
            case let .outcome(isCompleted):
                self = .outcome(isCompleted: false)
                return isCompleted
            }
        }

        @discardableResult
        mutating func toggleCompletion() -> Bool {
            isCompleted ? markPending() : complete()
        }

        @discardableResult
        mutating func incrementProgress() -> Bool {
            guard case var .progress(progress) = self else {
                return false
            }
            let didChange = progress.increment()
            self = .progress(progress)
            return didChange
        }

        @discardableResult
        mutating func decrementProgress() -> Bool {
            guard case var .progress(progress) = self else {
                return false
            }
            let didChange = progress.decrement()
            self = .progress(progress)
            return didChange
        }
    }

    /// Tracks the numeric state used to determine whether a goal is complete.
    struct Progress: Codable {
        /// The user's current progress toward the target value.
        private(set) var currentValue: Double
        /// The value at which the goal is considered complete.
        private(set) var targetValue: Double
        /// The amount used when stepping progress up or down.
        private(set) var incrementValue: Double

        /// Whether the current value has reached or exceeded the target value.
        var isCompleted: Bool {
            currentValue >= targetValue
        }

        var canDecrement: Bool {
            currentValue > 0
        }

        var canIncrement: Bool {
            currentValue < upperBound
        }

        /// The progress amount represented from 0 to 1.
        var fractionCompleted: Double {
            guard targetValue > 0 else {
                return isCompleted ? 1 : 0
            }
            return currentValue / targetValue
        }

        init(
            currentValue: Double,
            targetValue: Double,
            incrementValue: Double = 1,
        ) {
            precondition(
                Self.isValid(
                    currentValue: currentValue,
                    targetValue: targetValue,
                    incrementValue: incrementValue,
                ),
                "Progress values must be finite, non-negative, and within target bounds.",
            )
            self.currentValue = currentValue
            self.targetValue = targetValue
            self.incrementValue = incrementValue
        }

        static func isValid(
            currentValue: Double,
            targetValue: Double,
            incrementValue: Double,
        ) -> Bool {
            currentValue.isFinite
                && targetValue.isFinite
                && incrementValue.isFinite
                && currentValue >= 0
                && targetValue > 0
                && incrementValue > 0
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
        mutating func increment() -> Bool {
            setCurrentValue(currentValue + step)
        }

        @discardableResult
        mutating func decrement() -> Bool {
            setCurrentValue(currentValue - step)
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let currentValue = try container.decode(Double.self, forKey: .currentValue)
            let targetValue = try container.decode(Double.self, forKey: .targetValue)
            let incrementValue = try container.decodeIfPresent(Double.self, forKey: .incrementValue) ?? 1
            guard Self.isValid(
                currentValue: currentValue,
                targetValue: targetValue,
                incrementValue: incrementValue,
            ) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Progress values must be finite, non-negative, and within target bounds.",
                    ),
                )
            }
            self.currentValue = currentValue
            self.targetValue = targetValue
            self.incrementValue = incrementValue
        }

        private var upperBound: Double {
            max(0, targetValue)
        }

        private var step: Double {
            max(1, incrementValue)
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
}
