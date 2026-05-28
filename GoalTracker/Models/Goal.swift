//
//  Goal.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation
import SwiftData

extension GoalTrackerSchemaV1 {
    /// A goal the user wants to complete.
    ///
    /// `Goal` stores the current summary state for the goal, including its name,
    /// optional due date, and current progress.
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
        /// An optional reminder before the automatic due-date reminder.
        var earlyReminder: GoalReminder? = nil
        /// The current progress summary for this goal.
        var progress: GoalProgress = GoalProgress.outcomePending
        /// Reusable tags associated with this goal.
        var tags: [Tag] = []

        /// Whether the current progress has reached its target.
        var isCompleted: Bool {
            progress.isCompleted
        }

        /// The current user-facing status derived from progress.
        var status: GoalStatus {
            if isCompleted {
                return .completed
            }
            if progress.currentValue > 0 {
                return .inProgress
            }
            return .pending
        }

        @discardableResult
        func complete(timestamp: Date = Date()) -> Bool {
            progress.complete(timestamp: timestamp)
        }

        @discardableResult
        func toggleCompletion(timestamp: Date = Date()) -> Bool {
            progress.toggleCompletion(timestamp: timestamp)
        }

        @discardableResult
        func incrementProgress(timestamp: Date = Date()) -> Bool {
            progress.increment(timestamp: timestamp)
        }

        @discardableResult
        func decrementProgress(timestamp: Date = Date()) -> Bool {
            progress.decrement(timestamp: timestamp)
        }

        init(
            id: UUID = UUID(),
            name: String,
            details: String?,
            dueDate: Date? = nil,
            earlyReminder: GoalReminder? = nil,
            createdAt: Date,
            progress: GoalProgress,
        ) {
            self.id = id
            self.name = name
            self.details = details
            self.dueDate = dueDate
            self.earlyReminder = earlyReminder
            self.createdAt = createdAt
            self.progress = progress
        }
    }
}

typealias Goal = GoalTrackerSchemaV1.Goal
