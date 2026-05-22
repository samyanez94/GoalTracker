//
//  GoalReminderSchedule.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/22/26.
//

import Foundation

/// A validated reminder schedule that can be converted into a notification request.
struct GoalReminderSchedule {
    let goalId: UUID
    let goalName: String
    let dueDate: Date
    let reminderDate: Date

    init?(
        state: GoalReminderSyncState,
        calendar: Calendar,
        currentDate: Date,
    ) {
        guard !state.isCompleted,
              let dueDate = state.dueDate,
              let reminder = state.reminder,
              let reminderDate = reminder.reminderDate(
                before: dueDate,
                calendar: calendar,
              ),
              reminderDate > currentDate else {
            return nil
        }

        self.goalId = state.goalId
        self.goalName = state.goalName
        self.dueDate = dueDate
        self.reminderDate = reminderDate
    }
}
