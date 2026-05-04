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
    var kind: Kind
    var progress: Progress

    var isCompleted: Bool {
        progress.isCompleted
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String?,
        createdAt: Date,
        kind: Kind,
        progress: Progress,
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.kind = kind
        self.progress = progress
    }

    /// Describes how a goal is completed and how its progress should be interpreted.
    enum Kind: String, Codable {
        /// A goal completed by increasing a measurable value toward a target.
        case quantified
        /// A goal completed by achieving an outcome, represented as 0 out of 1 until it is done.
        case outcome
    }

    struct Progress: Codable {
        var currentValue: Double
        var targetValue: Double
        var incrementValue: Double

        var isCompleted: Bool {
            currentValue >= targetValue
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
