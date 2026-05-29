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
    let dueDate: Date?
    let reminder: GoalReminder?
    let isCompleted: Bool

    init(goal: Goal) {
        goalId = goal.id
        goalName = goal.name
        dueDate = goal.dueDate
        reminder = goal.reminder
        isCompleted = goal.isCompleted
    }
}
