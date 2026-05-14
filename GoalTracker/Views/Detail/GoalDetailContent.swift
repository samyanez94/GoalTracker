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
      if let details = goal.details,
        !details.isEmpty
      {
        Section("Description") {
          Text(details)
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

  private var progress: GoalProgress? {
    goal.progress.isMeasurable ? goal.progress : nil
  }

  private func formattedProgressValue(
    _ value: Double,
    for progress: GoalProgress,
  ) -> String {
    GoalProgressValueFormatter.string(
      from: value,
      unit: progress.unit,
    )
  }
}
