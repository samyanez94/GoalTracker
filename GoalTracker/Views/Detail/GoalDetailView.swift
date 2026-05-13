//
//  GoalDetailView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftUI

struct GoalDetailView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var editingGoal: Goal?

  @State private var feedbackTrigger = false

  let goalId: Goal.ID

  let goalStore: GoalStore

  var body: some View {
    if let goal {
      GoalDetailContent(goal: goal)
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Menu("Goal Actions", systemImage: "ellipsis") {
              Button {
                editingGoal = goal
              } label: {
                Label("Edit", systemImage: "pencil")
              }
              if let outcomeIsCompleted = outcomeIsCompleted(for: goal) {
                Button {
                  toggleOutcomeCompletion()
                } label: {
                  Label(
                    outcomeIsCompleted ? "Mark as Pending" : "Complete",
                    systemImage: outcomeIsCompleted ? "circle" : "checkmark.circle",
                  )
                }
              }
              Button(role: .destructive) {
                goalStore.deleteGoal(id: goal.id)
                dismiss()
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
            .labelStyle(.iconOnly)
          }
        }
        .sheet(item: $editingGoal) { currentGoal in
          NavigationStack {
            GoalFormView(
              mode: .edit(GoalFormData(goal: currentGoal)),
            ) { data in
              saveEdits(data)
            }
          }
        }
        .safeAreaInset(edge: .bottom) {
          GoalDetailBottomActionView(
            goal: goal,
            goalId: goalId,
            goalStore: goalStore,
            feedbackTrigger: $feedbackTrigger,
          ) {
            dismiss()
          }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger)
    } else {
      ContentUnavailableView("Goal Not Found", systemImage: "target")
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
    }
  }

  private var goal: Goal? {
    goalStore.goals.first { $0.id == goalId }
  }

  private func outcomeIsCompleted(for goal: Goal) -> Bool? {
    guard case .outcome(let isCompleted) = goal.completion else {
      return nil
    }
    return isCompleted
  }

  private func toggleOutcomeCompletion() {
    guard goalStore.toggleCompletion(id: goalId) else {
      return
    }
    feedbackTrigger.toggle()
  }

  private func saveEdits(_ data: GoalFormData) {
    goalStore.updateGoal(
      id: goalId,
      name: data.name,
      description: data.normalizedDescription,
      dueDate: data.dueDate,
      completion: data.completion,
    )
  }
}

#Preview("Incomplete Goal") {
  let goal = Goal(
    name: "Run a 5K",
    description: "Build up endurance with three runs per week.",
    createdAt: Date(),
    completion: .progress(Goal.Progress(currentValue: 1, targetValue: 5)),
  )
  let goalStore = GoalStore(goals: [goal])
  NavigationStack {
    GoalDetailView(
      goalId: goal.id,
      goalStore: goalStore,
    )
  }
}

#Preview("Completed Goal") {
  let goal = Goal(
    name: "Read every night",
    description: "Read for at least 20 minutes before bed.",
    createdAt: Date(),
    completion: .progress(Goal.Progress(currentValue: 20, targetValue: 20)),
  )
  let goalStore = GoalStore(goals: [goal])

  NavigationStack {
    GoalDetailView(
      goalId: goal.id,
      goalStore: goalStore,
    )
  }
}

#Preview("One-off Goal") {
  let goal = Goal(
    name: "Travel to Japan",
    description: "Plan and take the trip.",
    createdAt: Date(),
    completion: .outcome(isCompleted: false),
  )
  let goalStore = GoalStore(goals: [goal])

  NavigationStack {
    GoalDetailView(
      goalId: goal.id,
      goalStore: goalStore,
    )
  }
}
