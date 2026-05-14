//
//  Goal.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID = UUID()
    var name: String = ""
    var details: String?
    var createdAt: Date = Date()
    var dueDate: Date?
    var sortOrder: Int = 0
    var progress: GoalProgress = GoalProgress.outcomePending
    var recurrence: GoalRecurrence?
    var reminder: GoalReminder?

    @Relationship(deleteRule: .cascade, inverse: \GoalProgressEntry.goal)
    var progressEntries: [GoalProgressEntry] = []

    var isCompleted: Bool {
        progress.isCompleted
    }

    @discardableResult
    func complete() -> Bool {
        progress.complete()
    }

    @discardableResult
    func markPending() -> Bool {
        progress.reset()
    }

    @discardableResult
    func toggleCompletion() -> Bool {
        progress.toggleCompletion()
    }

    @discardableResult
    func incrementProgress() -> Bool {
        progress.increment()
    }

    @discardableResult
    func decrementProgress() -> Bool {
        progress.decrement()
    }

    init(
        id: UUID = UUID(),
        name: String,
        details: String?,
        dueDate: Date? = nil,
        createdAt: Date,
        sortOrder: Int = 0,
        progress: GoalProgress,
        recurrence: GoalRecurrence? = nil,
        reminder: GoalReminder? = nil,
        progressEntries: [GoalProgressEntry] = [],
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.progress = progress
        self.recurrence = recurrence
        self.reminder = reminder
        self.progressEntries = progressEntries
    }
}
