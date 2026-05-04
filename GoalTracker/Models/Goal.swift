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
    }

    /// Tracks the numeric state used to determine whether a goal is complete.
    struct Progress: Codable {
        /// The user's current progress toward the target value.
        var currentValue: Double
        /// The value at which the goal is considered complete.
        var targetValue: Double
        /// The amount used when stepping progress up or down.
        var incrementValue: Double

        /// Whether the current value has reached or exceeded the target value.
        var isCompleted: Bool {
            currentValue >= targetValue
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
            self.currentValue = currentValue
            self.targetValue = targetValue
            self.incrementValue = incrementValue
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            currentValue = try container.decode(Double.self, forKey: .currentValue)
            targetValue = try container.decode(Double.self, forKey: .targetValue)
            incrementValue = try container.decodeIfPresent(Double.self, forKey: .incrementValue) ?? 1
        }
    }
}
