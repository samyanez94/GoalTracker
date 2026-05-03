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
    var progress: Progress

    var isCompleted: Bool {
        progress.isCompleted
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String?,
        createdAt: Date,
        progress: Progress,
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.progress = progress
    }
    
    struct Progress: Codable {
        var currentValue: Double
        var targetValue: Double

        var isCompleted: Bool {
            currentValue >= targetValue
        }
    }
}
