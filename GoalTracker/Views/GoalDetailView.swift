//
//  GoalDetailView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftUI
import UIKit

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var goal: Goal

    @State private var isPresentingEditGoalView = false

    let onSave: (Goal) -> Void

    let onDelete: (Goal) -> Void

    init(
        goal: Goal,
        onSave: @escaping (Goal) -> Void,
        onDelete: @escaping (Goal) -> Void,
    ) {
        _goal = State(initialValue: goal)
        self.onSave = onSave
        self.onDelete = onDelete
    }

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
            Section("Status") {
                Text(goal.isCompleted ? "Completed" : "Pending")
                    .foregroundStyle(goal.isCompleted ? .blue : .secondary)
            }
            if let progress {
                Section("Current value") {
                    currentProgressRow()
                }
                Section("Target value") {
                    Text(progress.targetValue.formatted())
                }
            }
        }
        .navigationTitle("Goal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isPresentingEditGoalView = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        onDelete(goal)
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("Goal Actions")
            }
        }
        .sheet(isPresented: $isPresentingEditGoalView) {
            NavigationStack {
                GoalFormView(
                    title: "Edit Goal",
                    initialData: GoalFormData(goal: goal),
                ) { data in
                    saveEdits(data)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            callToActionButton
        }
    }

    private func currentProgressRow() -> some View {
        Text(progress?.currentValue.formatted() ?? "0")
    }

    private var currentProgressUpperBound: Double {
        max(0, progress?.targetValue ?? 0)
    }

    private var currentProgressStep: Double {
        max(1, progress?.incrementValue ?? 1)
    }

    private var progress: Goal.Progress? {
        guard case .progress(let progress) = goal.completion else {
            return nil
        }
        return progress
    }

    @ViewBuilder
    private var callToActionButton: some View {
        if progress != nil {
            ProgressStepperControl(
                canDecrement: !isProgressAtLowerBound,
                canIncrement: !isProgressAtUpperBound,
                onDecrement: decrementProgress,
                onIncrement: incrementProgress,
            )
        } else {
            CompleteGoalButton(isCompleted: goal.isCompleted) {
                playHapticFeedback()
                completeGoal()
                onSave(goal)
                dismiss()
            }
        }
    }

    private var isProgressAtLowerBound: Bool {
        guard let progress else {
            return true
        }
        return progress.currentValue <= 0
    }

    private var isProgressAtUpperBound: Bool {
        guard let progress else {
            return true
        }
        return progress.currentValue >= progress.targetValue
    }

    private func decrementProgress() {
        updateProgress { progress in
            progress.currentValue = max(0, progress.currentValue - currentProgressStep)
        }
        playHapticFeedback()
    }

    private func incrementProgress() {
        updateProgress { progress in
            progress.currentValue = min(currentProgressUpperBound, progress.currentValue + currentProgressStep)
        }
        playHapticFeedback()
    }

    private func updateProgress(_ update: (inout Goal.Progress) -> Void) {
        guard var progress else {
            return
        }
        update(&progress)
        goal.completion = .progress(progress)
        onSave(goal)
    }

    private func playHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func completeGoal() {
        switch goal.completion {
        case .progress(var progress):
            progress.currentValue = progress.targetValue
            goal.completion = .progress(progress)
        case .outcome:
            goal.completion = .outcome(isCompleted: true)
        }
    }

    private func saveEdits(_ data: GoalFormData) {
        goal.name = data.name
        goal.description = data.normalizedDescription
        goal.completion = data.completion
        onSave(goal)
    }
}

private struct ProgressStepperControl: View {
    let canDecrement: Bool
    let canIncrement: Bool
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            button(
                systemName: "minus",
                accessibilityLabel: "Decrease progress",
                action: onDecrement,
            )
            .disabled(!canDecrement)
            button(
                systemName: "plus",
                accessibilityLabel: "Increase progress",
                action: onIncrement,
            )
            .disabled(!canIncrement)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func button(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void,
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: GoalDetailBottomAction.height)
        }
        .tint(.blue)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct CompleteGoalButton: View {
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isCompleted ? "Completed" : "Complete")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: GoalDetailBottomAction.height)
        }
        .buttonStyle(.glassProminent)
        .disabled(isCompleted)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

private enum GoalDetailBottomAction {
    static let height: CGFloat = 44
}

#Preview("Incomplete Goal") {
    NavigationStack {
        GoalDetailView(
            goal: Goal(
                name: "Run a 5K",
                description: "Build up endurance with three runs per week.",
                createdAt: Date(),
                completion: .progress(Goal.Progress(currentValue: 1, targetValue: 5)),
            ),
            onSave: { _ in },
            onDelete: { _ in },
        )
    }
}

#Preview("Completed Goal") {
    NavigationStack {
        GoalDetailView(
            goal: Goal(
                name: "Read every night",
                description: "Read for at least 20 minutes before bed.",
                createdAt: Date(),
                completion: .progress(Goal.Progress(currentValue: 20, targetValue: 20)),
            ),
            onSave: { _ in },
            onDelete: { _ in },
        )
    }
}

#Preview("One-off Goal") {
    NavigationStack {
        GoalDetailView(
            goal: Goal(
                name: "Travel to Japan",
                description: "Plan and take the trip.",
                createdAt: Date(),
                completion: .outcome(isCompleted: false),
            ),
            onSave: { _ in },
            onDelete: { _ in },
        )
    }
}
