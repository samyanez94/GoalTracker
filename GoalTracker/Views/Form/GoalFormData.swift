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
    var progress: GoalProgress
    var tags: [Tag]

    static let empty = GoalFormData(
        name: "",
        details: "",
        dueDate: nil,
        progress: .outcomePending,
        tags: [],
    )

    init(goal: Goal) {
        name = goal.name
        details = goal.details ?? ""
        dueDate = goal.dueDate
        progress = goal.progress
        tags = goal.tags
    }

    init(
        name: String,
        details: String,
        dueDate: Date? = nil,
        progress: GoalProgress,
        tags: [Tag] = [],
    ) {
        self.name = name
        self.details = details
        self.dueDate = dueDate
        self.progress = progress
        self.tags = tags
    }

    var normalizedDetails: String? {
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedDetails.isEmpty ? nil : trimmedDetails
    }
}
