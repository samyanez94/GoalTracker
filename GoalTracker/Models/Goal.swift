//
//  Goal.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation
import SwiftData

/// A goal the user wants to complete.
///
/// `Goal` stores the current summary state for the goal, including its name,
/// optional due date, manual sort order, and current progress. Dated progress
/// history is stored separately in `progressEntries`.
@Model
final class Goal {
    /// A stable app-level identifier for navigation and lookups.
    var id: UUID = UUID()
    /// The short title shown in lists and detail screens.
    var name: String = ""
    /// Optional longer notes about the goal.
    var details: String?
    /// The date the goal was created.
    var createdAt: Date = Date()
    /// An optional target date for completing the goal.
    var dueDate: Date?
    /// The user's manual ordering value within pending or completed sections.
    var sortOrder: Int = 0
    /// The current progress summary for this goal.
    var progress: GoalProgress = GoalProgress.outcomePending

    /// Dated progress changes for charts and calendars.
    ///
    /// This relationship is optional so the model remains compatible with
    /// CloudKit-backed SwiftData.
    @Relationship(deleteRule: .cascade, inverse: \GoalProgressEntry.goal)
    var progressEntries: [GoalProgressEntry]? = []

    /// Whether the current progress has reached its target.
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
        progressEntries: [GoalProgressEntry]? = [],
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.progress = progress
        self.progressEntries = progressEntries
    }
}
