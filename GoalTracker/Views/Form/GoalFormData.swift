//
//  GoalFormData.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import Foundation

struct GoalFormData {
  var name: String
  var description: String
  var dueDate: Date?
  var progress: GoalProgress

  static let empty = GoalFormData(
    name: "",
    description: "",
    dueDate: nil,
    progress: .outcomePending,
  )

  init(goal: Goal) {
    name = goal.name
    description = goal.description ?? ""
    dueDate = goal.dueDate
    progress = goal.progress
  }

  init(
    name: String,
    description: String,
    dueDate: Date? = nil,
    progress: GoalProgress,
  ) {
    self.name = name
    self.description = description
    self.dueDate = dueDate
    self.progress = progress
  }

  var normalizedDescription: String? {
    let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedDescription.isEmpty ? nil : trimmedDescription
  }
}
