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

    @State private var isEditing = false

    @State private var editedName = ""

    @State private var editedDescription = ""

    @State private var editedCurrentValue = 0.0

    @State private var editedTargetValue = 1.0

    let onSave: (Goal) -> Void

    let onDelete: () -> Void

    init(goal: Goal, onSave: @escaping (Goal) -> Void, onDelete: @escaping () -> Void) {
        _goal = State(initialValue: goal)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    private var trimmedEditedName: String {
        editedName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEditedDescription: String {
        editedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSaveDisabled: Bool {
        trimmedEditedName.isEmpty || editedTargetValue <= 0
    }

    var body: some View {
        Form {
            Section("Name") {
                if isEditing {
                    TextField("Goal name", text: $editedName)
                } else {
                    Text(goal.name)
                }
            }
            Section("Description") {
                if isEditing {
                    TextField(
                        "Description (optional)",
                        text: $editedDescription,
                        axis: .vertical,
                    )
                    .lineLimit(1 ... 6)
                } else {
                    if let description = goal.description, !description.isEmpty {
                        Text(description)
                    } else {
                        Text("No description")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section("Status") {
                Text(goal.isCompleted ? "Completed" : "Pending")
                    .foregroundStyle(goal.isCompleted ? .blue : .secondary)
            }
            Section("Progress") {
                if isEditing {
                    progressTextFieldRow(
                        label: "Current value",
                        value: $editedCurrentValue,
                    )
                    progressTextFieldRow(
                        label: "Target value",
                        value: $editedTargetValue,
                    )
                } else {
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
                if isEditing {
                    Button("Done") {
                        saveEdits()
                    }
                    .disabled(isSaveDisabled)
                } else {
                    Menu {
                        Button {
                            startEditing()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            onDelete()
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
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelEditing()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !isEditing {
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

    private func progressTextFieldRow(label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func startEditing() {
        editedName = goal.name
        editedDescription = goal.description ?? ""
        editedCurrentValue = goal.progress.currentValue
        editedTargetValue = goal.progress.targetValue
        isEditing = true
    }

    private func cancelEditing() {
        editedName = goal.name
        editedDescription = goal.description ?? ""
        editedCurrentValue = goal.progress.currentValue
        editedTargetValue = goal.progress.targetValue
        isEditing = false
    }

    private func saveEdits() {
        goal.name = trimmedEditedName
        goal.description = trimmedEditedDescription.isEmpty ? nil : trimmedEditedDescription
        goal.progress = Goal.Progress(
            currentValue: editedCurrentValue,
            targetValue: editedTargetValue,
        )
        onSave(goal)
        isEditing = false
    }
}

#Preview("Incomplete Goal") {
    NavigationStack {
        GoalDetailView(
            goal: Goal(
                name: "Run a 5K",
                description: "Build up endurance with three runs per week.",
                createdAt: Date(),
                progress: Goal.Progress(currentValue: 1, targetValue: 5),
            ),
            onSave: { _ in },
            onDelete: {},
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
                progress: Goal.Progress(currentValue: 20, targetValue: 20),
            ),
            onSave: { _ in },
            onDelete: {},
        )
    }
}
