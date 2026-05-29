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
        /// An optional notification reminder for the due date.
        var reminder: GoalReminder? = nil
        /// The current progress summary for this goal.
        var progress: GoalProgress = GoalProgress.outcomePending
        /// Optional recurrence rules for goals that reset completion each cadence period.
        var recurrence: GoalRecurrence?
        /// Reusable tags associated with this goal.
        var tags: [Tag] = []

        /// Whether the current progress has reached its target.
        var isCompleted: Bool {
            isCompleted()
        }

        /// The current user-facing status derived from progress.
        var status: GoalStatus {
            status()
        }
        
        var isMeasurable: Bool {
            progress.isMeasurable
        }

        var isRecurring: Bool {
            recurrence != nil
        }

        func isCompleted(
            at date: Date = Date(),
            calendar: Calendar = .current,
        ) -> Bool {
            guard let period = recurrence?.period(containing: date, calendar: calendar) else {
                return progress.isCompleted
            }
            return progress.isCompleted(in: period)
        }

        func status(
            at date: Date = Date(),
            calendar: Calendar = .current,
        ) -> GoalStatus {
            if isCompleted(at: date, calendar: calendar) {
                return .completed
            }
            if currentProgressValue(at: date, calendar: calendar) > 0 {
                return .inProgress
            }
            return .pending
        }

        func currentProgressValue(
            at date: Date = Date(),
            calendar: Calendar = .current,
        ) -> Double {
            guard let period = recurrence?.period(containing: date, calendar: calendar) else {
                return progress.currentValue
            }
            return progress.currentValue(in: period)
        }

        func currentStreak(
            at date: Date = Date(),
            calendar: Calendar = .current,
        ) -> Int? {
            guard let recurrence else {
                return nil
            }
            var streak = 0
            var period = recurrence.period(containing: date, calendar: calendar)
            if let currentPeriod = period,
               !progress.isCompleted(in: currentPeriod) {
                period = recurrence.period(before: currentPeriod, calendar: calendar)
            }
            while let currentPeriod = period,
                  progress.isCompleted(in: currentPeriod) {
                streak += 1
                period = recurrence.period(before: currentPeriod, calendar: calendar)
            }
            return streak
        }

        func canDecrementProgress(
            at date: Date = Date(),
            calendar: Calendar = .current,
        ) -> Bool {
            guard let period = recurrence?.period(containing: date, calendar: calendar) else {
                return progress.canDecrement
            }
            return progress.canDecrement(in: period)
        }

        func canIncrementProgress(
            at date: Date = Date(),
            calendar: Calendar = .current,
        ) -> Bool {
            guard let period = recurrence?.period(containing: date, calendar: calendar) else {
                return progress.canIncrement
            }
            return progress.canIncrement(in: period)
        }

        @discardableResult
        func complete(
            timestamp: Date = Date(),
            calendar: Calendar = .current,
        ) -> Bool {
            guard let period = recurrence?.period(containing: timestamp, calendar: calendar) else {
                return progress.complete(timestamp: timestamp)
            }
            return progress.complete(in: period, timestamp: timestamp)
        }

        @discardableResult
        func toggleCompletion(
            timestamp: Date = Date(),
            calendar: Calendar = .current,
        ) -> Bool {
            guard let period = recurrence?.period(containing: timestamp, calendar: calendar) else {
                return progress.toggleCompletion(timestamp: timestamp)
            }
            return progress.toggleCompletion(in: period, timestamp: timestamp)
        }

        @discardableResult
        func incrementProgress(
            timestamp: Date = Date(),
            calendar: Calendar = .current,
        ) -> Bool {
            guard let period = recurrence?.period(containing: timestamp, calendar: calendar) else {
                return progress.increment(timestamp: timestamp)
            }
            return progress.increment(in: period, timestamp: timestamp)
        }

        @discardableResult
        func decrementProgress(
            timestamp: Date = Date(),
            calendar: Calendar = .current,
        ) -> Bool {
            guard let period = recurrence?.period(containing: timestamp, calendar: calendar) else {
                return progress.decrement(timestamp: timestamp)
            }
            return progress.decrement(in: period, timestamp: timestamp)
        }

        init(
            id: UUID = UUID(),
            name: String,
            details: String?,
            dueDate: Date? = nil,
            reminder: GoalReminder? = nil,
            createdAt: Date,
            progress: GoalProgress,
            recurrence: GoalRecurrence? = nil,
        ) {
            self.id = id
            self.name = name
            self.details = details
            self.dueDate = dueDate
            self.reminder = reminder
            self.createdAt = createdAt
            self.progress = progress
            self.recurrence = recurrence
        }
    }
}

typealias Goal = GoalTrackerSchemaV1.Goal
