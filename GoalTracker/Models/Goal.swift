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
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String?,
        createdAt: Date,
        isCompleted: Bool,
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.isCompleted = isCompleted
    }
}
