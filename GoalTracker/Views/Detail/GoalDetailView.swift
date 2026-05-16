//
//  GoalDetailView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftData
import SwiftUI

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @Environment(\.modelContext) private var modelContext

    @State private var isPresentingEditForm = false

    @State private var feedbackTrigger = false

    @State private var saveFailure: GoalSaveFailure?

    let goal: Goal

    var body: some View {
        GoalDetailContent(goal: goal)
            .navigationTitle("Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Goal Actions", systemImage: "ellipsis") {
                        Button {
                            isPresentingEditForm = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        if let outcomeIsCompleted = outcomeIsCompleted(for: goal) {
                            Button {
                                toggleOutcomeCompletion()
                            } label: {
                                Label(
                                    outcomeIsCompleted ? "Mark as Pending" : "Complete",
                                    systemImage: outcomeIsCompleted
                                        ? "circle" : "checkmark.circle",
                                )
                            }
                        }
                        Button(role: .destructive) {
                            deleteGoal(goal)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .sheet(isPresented: $isPresentingEditForm) {
                NavigationStack {
                    GoalFormView(
                        mode: .edit(GoalFormData(goal: goal)),
                    ) { data in
                        try updateGoal(data)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                GoalDetailBottomActionView(
                    goal: goal,
                    feedbackTrigger: $feedbackTrigger,
                ) {
                    dismiss()
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger)
            .goalSaveFailureAlert(failure: $saveFailure)
    }

    private var goalManager: GoalManager {
        GoalManager(modelContext: modelContext)
    }

    private func outcomeIsCompleted(for goal: Goal) -> Bool? {
        guard goal.progress.kind == .outcome else {
            return nil
        }
        return goal.progress.isCompleted
    }

    private func toggleOutcomeCompletion() {
        do {
            guard try goalManager.toggleCompletion(goal) else {
                return
            }
            feedbackTrigger.toggle()
        } catch {
            saveFailure = .updateProgress
        }
    }

    private func updateGoal(_ data: GoalFormData) throws {
        try goalManager.updateGoal(
            goal,
            name: data.name,
            details: data.normalizedDetails,
            dueDate: data.dueDate,
            progress: data.progress,
        )
    }

    private func deleteGoal(_ goal: Goal) {
        do {
            try goalManager.deleteGoal(goal)
            dismiss()
        } catch {
            saveFailure = .deleteGoal
        }
    }
}

#Preview("Outcome goal") {
    NavigationStack {
        GoalDetailView(
            goal: Goal(
                name: "Travel to Japan",
                details: "Plan and take the trip.",
                createdAt: Date(),
                progress: .outcomePending,
            )
        )
    }
}

#Preview("Measurable goal") {
    NavigationStack {
        GoalDetailView(
            goal: Goal(
                name: "Run a 5K",
                details: "Build up endurance with three runs per week.",
                createdAt: Date(),
                progress: .measurable(currentValue: 1, targetValue: 5),
            )
        )
    }
}
