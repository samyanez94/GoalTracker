//
//  Goal.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation
import SwiftData

// MARK: - GoalTrackerSchemaV1.Goal

extension GoalTrackerSchemaV1 {
	/// A model representing a goal the user is working toward.
	///
	/// A goal combines user-editable details, scheduling metadata, tags, and progress state. For recurring goals, completion and progress are evaluated within the relevant recurrence period; otherwise, they are evaluated against the goal's overall progress history.
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
		var targetDate: Date?
		/// An optional notification reminder for the target date or recurring cadence.
		var reminder: GoalReminder? = nil
		/// The current progress summary for this goal.
		var progress: GoalProgress = GoalProgress.outcome(OutcomeProgress())
		/// Optional recurrence rules for goals that reset completion each cadence period.
		var recurrence: GoalRecurrence?
		/// Reusable tags associated with this goal.
		var tags: [Tag]? = []

		/// Whether the goal is recurring.
		var isRecurring: Bool { recurrence != nil }

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

		func isCompleted(
			at date: Date = Date(),
			calendar: Calendar = .current,
		) -> Bool {
			guard let period = recurrence?.period(containing: date, calendar: calendar) else {
				return progress.isCompleted
			}
			return progress.isCompleted(in: period)
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

		func isPastTargetDate(
			at date: Date = Date(),
			calendar: Calendar = .current,
		) -> Bool {
			guard let targetDate,
				!isCompleted(at: date, calendar: calendar)
			else {
				return false
			}
			return calendar.startOfDay(for: targetDate) < calendar.startOfDay(for: date)
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
				!progress.isCompleted(in: currentPeriod)
			{
				period = recurrence.period(before: currentPeriod, calendar: calendar)
			}
			while let currentPeriod = period,
				progress.isCompleted(in: currentPeriod)
			{
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

		@discardableResult
		func updateProgress(
			by amount: Double,
			timestamp: Date = Date(),
			calendar: Calendar = .current,
		) -> Bool {
			guard let period = recurrence?.period(containing: timestamp, calendar: calendar) else {
				return progress.update(by: amount, timestamp: timestamp)
			}
			return progress.update(by: amount, in: period, timestamp: timestamp)
		}

		init(
			id: UUID = UUID(),
			name: String,
			details: String? = nil,
			targetDate: Date? = nil,
			reminder: GoalReminder? = nil,
			createdAt: Date = Date(),
			progress: GoalProgress,
			recurrence: GoalRecurrence? = nil,
		) {
			self.id = id
			self.name = name
			self.details = details
			self.targetDate = targetDate
			self.reminder = reminder
			self.createdAt = createdAt
			self.progress = progress
			self.recurrence = recurrence
		}
	}
}

// MARK: - Goal

typealias Goal = GoalTrackerSchemaV1.Goal
