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
    let fireDate: Date

    static func reminder(
        state: GoalReminderSyncState,
        calendar: Calendar,
        currentDate: Date,
    ) -> GoalReminderSchedule? {
        guard !state.isCompleted,
              let dueDate = state.dueDate,
              let reminder = state.reminder,
              let fireDate = reminder.fireDate(
                on: dueDate,
                calendar: calendar,
              ),
              fireDate > currentDate else {
            return nil
        }
        return GoalReminderSchedule(
            state: state,
            dueDate: dueDate,
            fireDate: fireDate,
        )
    }

    private init(
        state: GoalReminderSyncState,
        dueDate: Date,
        fireDate: Date,
    ) {
        self.goalId = state.goalId
        self.goalName = state.goalName
        self.dueDate = dueDate
        self.fireDate = fireDate
    }
}
