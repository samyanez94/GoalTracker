//
//  GoalDetailView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftUI

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var goal: Goal

    @State private var isPresentingEditGoalView = false

    let onSave: (Goal) -> Void

    let onDelete: (Goal) -> Void

    init(
        goal: Goal,
        onSave: @escaping (Goal) -> Void,
        onDelete: @escaping (Goal) -> Void
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
               !description.isEmpty {
                Section("Description") {
                    Text(description)
                }
            }
            Section("Status") {
                Text(goal.isCompleted ? "Completed" : "Pending")
                    .foregroundStyle(goal.isCompleted ? .blue : .secondary)
            }
            if goal.kind == .quantified {
                Section("Progress") {
                    progressTextRow(
                        label: "Current value",
                        value: goal.progress.currentValue,
                    )
                    progressTextRow(
                        label: "Target value",
                        value: goal.progress.targetValue,
                    )
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
            Button {
                goal.progress.currentValue = goal.progress.targetValue
                onSave(goal)
                dismiss()
            } label: {
                Text(goal.isCompleted ? "Completed" : "Complete")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(goal.isCompleted)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private func progressTextRow(label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value.formatted())
                .multilineTextAlignment(.trailing)
        }
    }

    private func saveEdits(_ data: GoalFormData) {
        goal.name = data.name
        goal.description = data.normalizedDescription
        goal.kind = data.kind
        goal.progress = data.progress
        onSave(goal)
    }
}

#Preview("Incomplete Goal") {
    NavigationStack {
        GoalDetailView(
            goal: Goal(
                name: "Run a 5K",
                description: "Build up endurance with three runs per week.",
                createdAt: Date(),
                kind: .quantified,
                progress: Goal.Progress(currentValue: 1, targetValue: 5),
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
                kind: .quantified,
                progress: Goal.Progress(currentValue: 20, targetValue: 20),
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
                kind: .outcome,
                progress: Goal.Progress(currentValue: 0, targetValue: 1),
            ),
            onSave: { _ in },
            onDelete: { _ in },
        )
    }
}
