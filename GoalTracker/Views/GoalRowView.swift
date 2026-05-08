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

    let onToggleCompletion: (Goal) -> Void

    var body: some View {
        NavigationLink {
            GoalDetailView(
                goalId: goal.id,
                goalStore: goalStore,
            )
        } label: {
            HStack(spacing: 12) {
                CircularGoalProgressView(
                    progress: goal.completion.fractionCompleted,
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
        .swipeActions(edge: .leading) {
            Button {
                onToggleCompletion(goal)
            } label: {
                Label(
                    goal.isCompleted ? "Mark as Pending" : "Complete",
                    systemImage: goal.isCompleted ? "arrow.uturn.backward" : "checkmark",
                )
            }
            .tint(goal.isCompleted ? .gray : .blue)
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

private struct CircularGoalProgressView: View {
    let progress: Double

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.blue.opacity(0.25), lineWidth: 5)
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    .blue,
                    style: StrokeStyle(
                        lineWidth: 5,
                        lineCap: .round,
                    ),
                )
                .rotationEffect(.degrees(-90))
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    let goalStore = GoalStore(
        goals: [
            Goal(
                name: "Run a 5K",
                description: "Build up endurance with three runs per week.",
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                createdAt: Date(),
                completion: .progress(Goal.Progress(currentValue: 2, targetValue: 5)),
            ),
            Goal(
                name: "File taxes",
                description: nil,
                dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                createdAt: Date(),
                completion: .outcome(isCompleted: false),
            ),
            Goal(
                name: "Travel to Japan",
                description: "Plan and take the trip.",
                createdAt: Date(),
                completion: .outcome(isCompleted: true),
            ),
        ],
    )

    NavigationStack {
        List {
            ForEach(goalStore.goals) { goal in
                GoalRowView(
                    goal: goal,
                    goalStore: goalStore,
                    onToggleCompletion: { _ in },
                )
            }
        }
    }
}
