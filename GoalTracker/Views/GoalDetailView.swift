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
                    if let outcomeIsCompleted {
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

    private var progress: Goal.Progress? {
        guard case let .progress(progress) = goal.completion else {
            return nil
        }
        return progress
    }

    private var outcomeIsCompleted: Bool? {
        guard case let .outcome(isCompleted) = goal.completion else {
            return nil
        }
        return isCompleted
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
        return !progress.canDecrement
    }

    private var isProgressAtUpperBound: Bool {
        guard let progress else {
            return true
        }
        return !progress.canIncrement
    }

    private func decrementProgress() {
        guard goal.decrementProgress() else {
            return
        }
        onSave(goal)
        playHapticFeedback()
    }

    private func incrementProgress() {
        guard goal.incrementProgress() else {
            return
        }
        onSave(goal)
        playHapticFeedback()
    }

    private func playHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func toggleOutcomeCompletion() {
        guard goal.toggleCompletion() else {
            return
        }
        playHapticFeedback()
        onSave(goal)
    }

    private func completeGoal() {
        goal.complete()
    }

    private func saveEdits(_ data: GoalFormData) {
        goal.name = data.name
        goal.description = data.normalizedDescription
        goal.dueDate = data.dueDate
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
            RepeatingStepperButton(
                systemName: "minus",
                accessibilityLabel: "Decrease progress",
                action: onDecrement,
            )
            .disabled(!canDecrement)
            RepeatingStepperButton(
                systemName: "plus",
                accessibilityLabel: "Increase progress",
                action: onIncrement,
            )
            .disabled(!canIncrement)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

private struct RepeatingStepperButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void

    @State private var repeatTask: Task<Void, Never>?

    var body: some View {
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
        .onLongPressGesture(
            minimumDuration: 0.35,
            perform: {},
            onPressingChanged: { isPressing in
                if isPressing {
                    startRepeating()
                } else {
                    stopRepeating()
                }
            },
        )
        .onDisappear {
            stopRepeating()
        }
    }

    private func startRepeating() {
        guard repeatTask == nil else {
            return
        }
        repeatTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            while !Task.isCancelled {
                action()
                try? await Task.sleep(for: .milliseconds(120))
            }
        }
    }

    private func stopRepeating() {
        repeatTask?.cancel()
        repeatTask = nil
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
