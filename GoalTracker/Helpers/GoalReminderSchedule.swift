//
//  GoalReminderSchedule.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/22/26.
//

import Foundation

/// A validated reminder schedule that can be converted into a notification request.
struct GoalReminderSchedule {
	enum DueDescription {
		case date(Date)
		case cadence(GoalRecurrenceCadence)
	}

	let goalId: UUID
	let goalName: String
	let dueDescription: DueDescription
	let triggerDateComponents: DateComponents
	let repeats: Bool

	static func reminder(
		state: GoalReminderSyncState,
		calendar: Calendar,
		currentDate: Date,
	) -> GoalReminderSchedule? {
		guard let reminder = state.reminder else {
			return nil
		}
		if let recurrence = state.recurrence {
			return recurringReminder(
				state: state,
				recurrence: recurrence,
				calendar: calendar,
			)
		}
		return oneTimeReminder(
			state: state,
			reminder: reminder,
			calendar: calendar,
			currentDate: currentDate,
		)
	}

	private static func oneTimeReminder(
		state: GoalReminderSyncState,
		reminder: GoalReminder,
		calendar: Calendar,
		currentDate: Date,
	) -> GoalReminderSchedule? {
		guard !state.progress.isCompleted,
			let dueDate = state.dueDate,
			let fireDate = reminder.fireDate(
				on: dueDate,
				calendar: calendar,
			),
			fireDate > currentDate
		else {
			return nil
		}
		return GoalReminderSchedule(
			state: state,
			dueDescription: .date(dueDate),
			fireDate: fireDate,
			calendar: calendar,
		)
	}

	private static func recurringReminder(
		state: GoalReminderSyncState,
		recurrence: GoalRecurrence,
		calendar: Calendar,
	) -> GoalReminderSchedule {
		GoalReminderSchedule(
			state: state,
			dueDescription: .cadence(recurrence.cadence),
			triggerDateComponents: recurrence.cadence.reminderDateComponents(calendar: calendar),
			repeats: true,
		)
	}

	private init(
		state: GoalReminderSyncState,
		dueDescription: DueDescription,
		fireDate: Date,
		calendar: Calendar,
	) {
		self.goalId = state.goalId
		self.goalName = state.goalName
		self.dueDescription = dueDescription
		self.triggerDateComponents = calendar.dateComponents(
			[.year, .month, .day, .hour, .minute, .second],
			from: fireDate,
		)
		self.repeats = false
	}

	private init(
		state: GoalReminderSyncState,
		dueDescription: DueDescription,
		triggerDateComponents: DateComponents,
		repeats: Bool,
	) {
		self.goalId = state.goalId
		self.goalName = state.goalName
		self.dueDescription = dueDescription
		self.triggerDateComponents = triggerDateComponents
		self.repeats = repeats
	}
}
