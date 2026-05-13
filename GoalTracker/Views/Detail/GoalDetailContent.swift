//
//  GoalDetailContent.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct GoalDetailContent: View {
  let goal: Goal

  var body: some View {
    Form {
      Section("Name") {
        Text(goal.name)
      }
      if let description = goal.description,
        !description.isEmpty
      {
        Section("Description") {
          Text(description)
        }
      }
      if let dueDate = goal.dueDate {
        Section("Due Date") {
          Label {
            Text(GoalDueDateFormatter.string(from: dueDate))
          } icon: {
            Image(systemName: "calendar")
              .foregroundStyle(.secondary)
          }
        }
      }
      Section("Status") {
        Text(goal.isCompleted ? "Completed" : "Pending")
          .foregroundStyle(goal.isCompleted ? .blue : .secondary)
      }
      if let progress {
        Section("Current") {
          Text(formattedProgressValue(progress.currentValue, for: progress))
        }
        Section("Target") {
          Text(formattedProgressValue(progress.targetValue, for: progress))
        }
      }
    }
  }

  private var progress: Goal.Progress? {
    guard case .progress(let progress) = goal.completion else {
      return nil
    }
    return progress
  }

  private func formattedProgressValue(
    _ value: Double,
    for progress: Goal.Progress,
  ) -> String {
    GoalProgressValueFormatter.string(
      from: value,
      unit: progress.unit,
    )
  }
}
