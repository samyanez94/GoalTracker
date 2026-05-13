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
  var completion: Goal.Completion

  static let empty = GoalFormData(
    name: "",
    description: "",
    dueDate: nil,
    completion: .outcome(isCompleted: false),
  )

  init(goal: Goal) {
    name = goal.name
    description = goal.description ?? ""
    dueDate = goal.dueDate
    completion = goal.completion
  }

  init(
    name: String,
    description: String,
    dueDate: Date? = nil,
    completion: Goal.Completion,
  ) {
    self.name = name
    self.description = description
    self.dueDate = dueDate
    self.completion = completion
  }

  var normalizedDescription: String? {
    let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedDescription.isEmpty ? nil : trimmedDescription
  }
}
