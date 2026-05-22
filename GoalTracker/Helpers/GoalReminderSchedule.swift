//
//  GoalReminderSchedule.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/22/26.
//

import Foundation

/// A validated reminder schedule that can be converted into a notification request.
struct GoalReminderSchedule {
    enum Kind {
        case dueDate
        case early
    }

    let kind: Kind
    let goalId: UUID
    let goalName: String
    let dueDate: Date
    let fireDate: Date

    static func dueDateReminder(
        state: GoalReminderSyncState,
        calendar: Calendar,
        currentDate: Date,
    ) -> GoalReminderSchedule? {
        guard !state.isCompleted,
              let dueDate = state.dueDate,
              let fireDate = calendar.date(
                bySettingHour: GoalReminder.defaultSettingHour,
                minute: 0,
                second: 0,
                of: dueDate,
              ),
              fireDate > currentDate else {
            return nil
        }
        return GoalReminderSchedule(
            kind: .dueDate,
            state: state,
            dueDate: dueDate,
            fireDate: fireDate,
        )
    }

    static func earlyReminder(
        state: GoalReminderSyncState,
        calendar: Calendar,
        currentDate: Date,
    ) -> GoalReminderSchedule? {
        guard !state.isCompleted,
              let dueDate = state.dueDate,
              let earlyReminder = state.earlyReminder,
              let fireDate = earlyReminder.reminderDate(
                before: dueDate,
                calendar: calendar,
              ),
              fireDate > currentDate else {
            return nil
        }
        return GoalReminderSchedule(
            kind: .early,
            state: state,
            dueDate: dueDate,
            fireDate: fireDate,
        )
    }

    private init(
        kind: Kind,
        state: GoalReminderSyncState,
        dueDate: Date,
        fireDate: Date,
    ) {
        self.kind = kind
        self.goalId = state.goalId
        self.goalName = state.goalName
        self.dueDate = dueDate
        self.fireDate = fireDate
    }
}
