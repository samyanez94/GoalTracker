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

    @State private var isPresentingEditGoalView = false

    let goalId: Goal.ID

    let goalStore: GoalStore

    var body: some View {
        if let goal {
            detailContent(for: goal)
        } else {
            ContentUnavailableView("Goal Not Found", systemImage: "target")
                .navigationTitle("Goal Details")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var goal: Goal? {
        goalStore.goals.first { $0.id == goalId }
    }

    private func detailContent(for goal: Goal) -> some View {
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
            if let progress = progress(for: goal) {
                Section("Current value") {
                    currentProgressRow(for: progress)
                }
                Section("Target value") {
                    Text(formattedProgressValue(progress.targetValue, for: progress))
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
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("Goal Actions")
            }
        }
        .sheet(isPresented: $isPresentingEditGoalView) {
            NavigationStack {
                if let currentGoal = self.goal {
                    GoalFormView(
                        mode: .edit(GoalFormData(goal: currentGoal)),
                    ) { data in
                        saveEdits(data)
                    }
                } else {
                    ContentUnavailableView("Goal Not Found", systemImage: "target")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            callToActionButton(for: goal)
        }
    }

    private func currentProgressRow(for progress: Goal.Progress) -> some View {
        Text(formattedProgressValue(progress.currentValue, for: progress))
    }

    private func formattedProgressValue(
        _ value: Double,
        for progress: Goal.Progress,
    ) -> String {
        GoalProgressValueFormatter.string(
            from: value,
            unit: progress.unit,
        )
    }

    private func progress(for goal: Goal) -> Goal.Progress? {
        guard case let .progress(progress) = goal.completion else {
            return nil
        }
        return progress
    }

    private func outcomeIsCompleted(for goal: Goal) -> Bool? {
        guard case let .outcome(isCompleted) = goal.completion else {
            return nil
        }
        return isCompleted
    }

    @ViewBuilder
    private func callToActionButton(for goal: Goal) -> some View {
        if progress(for: goal) != nil {
            ProgressStepperControl(
                canDecrement: !isProgressAtLowerBound(goal),
                canIncrement: !isProgressAtUpperBound(goal),
                onDecrement: decrementProgress,
                onIncrement: incrementProgress,
            )
        } else {
            CompleteGoalButton(isCompleted: goal.isCompleted) {
                if completeGoal() {
                    playHapticFeedback()
                }
                dismiss()
            }
        }
    }

    private func isProgressAtLowerBound(_ goal: Goal) -> Bool {
        guard let progress = progress(for: goal) else {
            return true
        }
        return !progress.canDecrement
    }

    private func isProgressAtUpperBound(_ goal: Goal) -> Bool {
        guard let progress = progress(for: goal) else {
            return true
        }
        return !progress.canIncrement
    }

    private func decrementProgress() {
        guard goalStore.decrementProgress(id: goalId) else {
            return
        }
        playHapticFeedback()
    }

    private func incrementProgress() {
        guard goalStore.incrementProgress(id: goalId) else {
            return
        }
        playHapticFeedback()
    }

    private func playHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func toggleOutcomeCompletion() {
        guard goalStore.toggleCompletion(id: goalId) else {
            return
        }
        playHapticFeedback()
    }

    private func completeGoal() -> Bool {
        goalStore.completeGoal(id: goalId)
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
