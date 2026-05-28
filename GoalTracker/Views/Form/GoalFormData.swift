//
//  GoalFormData.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import Foundation

struct GoalFormData {
    var name: String
    var details: String
    var dueDate: Date?
    var earlyReminder: GoalReminder?
    var progress: GoalProgress
    var recurrence: GoalRecurrence?
    var tags: [Tag]

    static let empty = GoalFormData(
        name: "",
        details: "",
        dueDate: nil,
        earlyReminder: nil,
        progress: .outcomePending,
        recurrence: nil,
        tags: [],
    )

    init(goal: Goal) {
        name = goal.name
        details = goal.details ?? ""
        dueDate = goal.dueDate
        earlyReminder = goal.earlyReminder
        progress = goal.progress
        recurrence = goal.recurrence
        tags = goal.tags
    }

    init(
        name: String,
        details: String,
        dueDate: Date? = nil,
        earlyReminder: GoalReminder? = nil,
        progress: GoalProgress,
        recurrence: GoalRecurrence? = nil,
        tags: [Tag] = [],
    ) {
        self.name = name
        self.details = details
        self.dueDate = dueDate
        self.earlyReminder = earlyReminder
        self.progress = progress
        self.recurrence = recurrence
        self.tags = tags
    }

    var normalizedDetails: String? {
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedDetails.isEmpty ? nil : trimmedDetails
    }
}
