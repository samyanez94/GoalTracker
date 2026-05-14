//
//  GoalRowView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/4/26.
//

import SwiftUI

struct GoalRowView: View {
  let goal: Goal

  let goalStore: GoalStore

  var body: some View {
    NavigationLink(value: goal.id) {
      HStack(spacing: 12) {
        CircularGoalProgressView(
          progress: goal.progress.fractionCompleted,
        )
        .frame(width: 24, height: 24)
        VStack(alignment: .leading, spacing: 2) {
          Text(goal.name)
            .foregroundStyle(goal.isCompleted ? .secondary : .primary)
          if let dueDate = goal.dueDate {
            Text(GoalDueDateFormatter.string(from: dueDate))
              .font(.subheadline)
              .foregroundStyle(isPastDue(dueDate) ? .red : .secondary)
          }
        }
      }
    }
    .swipeActions {
      Button(role: .destructive) {
        goalStore.deleteGoal(id: goal.id)
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }

  private func isPastDue(_ dueDate: Date) -> Bool {
    !goal.isCompleted
      && Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: Date())
  }
}

#Preview {
  let goalStore = GoalStore(
    goals: [
      Goal(
        name: "Run a 5K",
        details: "Build up endurance with three runs per week.",
        dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
        createdAt: Date(),
        progress: .measurable(currentValue: 2, targetValue: 5),
      ),
      Goal(
        name: "File taxes",
        details: nil,
        dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
        createdAt: Date(),
        progress: .outcomePending,
      ),
      Goal(
        name: "Travel to Japan",
        details: "Plan and take the trip.",
        createdAt: Date(),
        progress: .outcomeCompleted,
      ),
    ],
  )

  NavigationStack {
    List {
      ForEach(goalStore.goals) { goal in
        GoalRowView(
          goal: goal,
          goalStore: goalStore,
        )
      }
    }
  }
}
