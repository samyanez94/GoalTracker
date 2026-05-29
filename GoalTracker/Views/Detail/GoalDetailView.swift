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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                GoalDetailHeaderSection(goal: goal)
                if goal.isRecurring {
                    GoalDetailStreakSection(goal: goal)
                }
                if goal.isMeasurable {
                    GoalDetailProgressSection(goal: goal)
                } else {
                    GoalDetailStatusSection(goal: goal)
                }
            }
        }
        .safeAreaPadding(.horizontal)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Goal Actions", systemImage: "ellipsis") {
                    GoalActionMenuItems(
                        isCompleted: goal.isCompleted,
                        edit: {
                            isPresentingEditForm = true
                        },
                        toggleCompletion: toggleCompletion,
                        delete: {
                            deleteGoal(goal)
                        },
                    )
                }
                .labelStyle(.iconOnly)
            }
        }
        .sheet(isPresented: $isPresentingEditForm) {
            NavigationStack {
                GoalFormView(
                    mode: .edit(GoalFormData(goal: goal)),
                ) { data in
                    try goalManager.updateGoal(goal, with: data)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            GoalDetailBottomActionView(
                goal: goal,
                feedbackTrigger: $feedbackTrigger,
            )
        }
        .sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger)
        .goalSaveFailureAlert(failure: $saveFailure)
    }

    private var goalManager: GoalManager {
        GoalManager(modelContext: modelContext)
    }

    private func toggleCompletion() {
        do {
            guard try goalManager.toggleCompletion(goal) else {
                return
            }
            feedbackTrigger.toggle()
        } catch {
            saveFailure = .updateProgress
        }
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
