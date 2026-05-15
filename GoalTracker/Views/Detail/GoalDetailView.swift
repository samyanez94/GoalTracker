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

    @Query private var goals: [Goal]

    @State private var editingGoal: Goal?

    @State private var feedbackTrigger = false

    @State private var saveFailure: GoalSaveFailure?

    let goalId: Goal.ID

    init(goalId: Goal.ID) {
        self.goalId = goalId
        _goals = Query(
            filter: #Predicate<Goal> { goal in
                goal.id == goalId
            },
        )
    }

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
                .sheet(item: $editingGoal) { currentGoal in
                    NavigationStack {
                        GoalFormView(
                            mode: .edit(GoalFormData(goal: currentGoal)),
                        ) { data in
                            try saveEdits(data)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    GoalDetailBottomActionView(
                        goal: goal,
                        goalManager: goalManager,
                        feedbackTrigger: $feedbackTrigger,
                    ) {
                        dismiss()
                    }
                }
                .sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger)
                .goalSaveFailureAlert(failure: $saveFailure)
        } else {
            ContentUnavailableView("Goal Not Found", systemImage: "target")
                .navigationTitle("Goal")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var goal: Goal? {
        goals.first { $0.id == goalId }
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
            guard let goal,
                try goalManager.toggleCompletion(goal)
            else {
                return
            }
            feedbackTrigger.toggle()
        } catch {
            saveFailure = .updateProgress
        }
    }

    private func saveEdits(_ data: GoalFormData) throws {
        guard let goal else {
            return
        }
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

#Preview("Incomplete Goal") {
    let goal = Goal(
        name: "Run a 5K",
        details: "Build up endurance with three runs per week.",
        createdAt: Date(),
        progress: .measurable(currentValue: 1, targetValue: 5),
    )
    let container = GoalPreviewContainer.make(goals: [goal])

    NavigationStack {
        GoalDetailView(goalId: goal.id)
    }
    .modelContainer(container)
}

#Preview("Completed Goal") {
    let goal = Goal(
        name: "Read every night",
        details: "Read for at least 20 minutes before bed.",
        createdAt: Date(),
        progress: .measurable(currentValue: 20, targetValue: 20),
    )
    let container = GoalPreviewContainer.make(goals: [goal])

    NavigationStack {
        GoalDetailView(goalId: goal.id)
    }
    .modelContainer(container)
}

#Preview("One-off Goal") {
    let goal = Goal(
        name: "Travel to Japan",
        details: "Plan and take the trip.",
        createdAt: Date(),
        progress: .outcomePending,
    )
    let container = GoalPreviewContainer.make(goals: [goal])

    NavigationStack {
        GoalDetailView(goalId: goal.id)
    }
    .modelContainer(container)
}
