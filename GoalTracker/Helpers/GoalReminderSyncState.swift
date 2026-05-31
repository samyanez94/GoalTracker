//
//  GoalReminderSyncState.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/22/26.
//

import Foundation

/// Immutable goal reminder state safe to pass across asynchronous scheduling work.
struct GoalReminderSyncState {
	let goalId: UUID
	let goalName: String
	let targetDate: Date?
	let reminder: GoalReminder?
	let progress: GoalProgress
	let recurrence: GoalRecurrence?

	init(goal: Goal) {
		goalId = goal.id
		goalName = goal.name
		targetDate = goal.targetDate
		reminder = goal.reminder
		progress = goal.progress
		recurrence = goal.recurrence
	}
}
