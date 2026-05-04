//
//  GoalRowView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/4/26.
//

import SwiftUI

struct GoalRowView: View {
    let goal: Goal

    let onSave: (Goal) -> Void

    let onDelete: (Goal) -> Void

    private var rowTint: Color {
        goal.isCompleted ? .secondary : .blue
    }

    var body: some View {
        NavigationLink {
            GoalDetailView(
                goal: goal,
                onSave: onSave,
                onDelete: onDelete,
            )
        } label: {
            HStack(spacing: 12) {
                CircularGoalProgressView(
                    progress: goal.progress.fractionCompleted,
                )
                .frame(width: 24, height: 24)
                Text(goal.name)
                    .foregroundStyle(goal.isCompleted ? .secondary : .primary)
            }
        }
        .swipeActions {
            Button(role: .destructive) {
                onDelete(goal)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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

private extension Goal.Progress {
    var fractionCompleted: Double {
        guard targetValue > 0 else {
            return isCompleted ? 1 : 0
        }
        return currentValue / targetValue
    }
}

#Preview {
    NavigationStack {
        List {
            GoalRowView(
                goal: Goal(
                    name: "Run a 5K",
                    description: "Build up endurance with three runs per week.",
                    createdAt: Date(),
                    kind: .quantified,
                    progress: Goal.Progress(currentValue: 2, targetValue: 5),
                ),
                onSave: { _ in },
                onDelete: { _ in },
            )

            GoalRowView(
                goal: Goal(
                    name: "Travel to Japan",
                    description: "Plan and take the trip.",
                    createdAt: Date(),
                    kind: .outcome,
                    progress: Goal.Progress(currentValue: 1, targetValue: 1),
                ),
                onSave: { _ in },
                onDelete: { _ in },
            )
        }
    }
}
