//
//  GoalDetailView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftUI

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var goal: Goal

    @State private var isEditing = false

    @State private var editedName = ""

    @State private var editedDescription = ""

    @State private var editedIsCompleted = false

    let onDelete: () -> Void

    private var trimmedEditedName: String {
        editedName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEditedDescription: String {
        editedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
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
                if isEditing {
                    Picker("Status", selection: $editedIsCompleted) {
                        Text("Pending").tag(false)
                        Text("Completed").tag(true)
                    }
                    .pickerStyle(.menu)
                } else {
                    Text(goal.isCompleted ? "Completed" : "Not Completed")
                        .foregroundStyle(goal.isCompleted ? .blue : .secondary)
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
                    .disabled(trimmedEditedName.isEmpty)
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
                    goal.isCompleted = true
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

    private func startEditing() {
        editedName = goal.name
        editedDescription = goal.description ?? ""
        editedIsCompleted = goal.isCompleted
        isEditing = true
    }

    private func cancelEditing() {
        editedName = goal.name
        editedDescription = goal.description ?? ""
        editedIsCompleted = goal.isCompleted
        isEditing = false
    }

    private func saveEdits() {
        goal.name = trimmedEditedName
        goal.description = trimmedEditedDescription.isEmpty ? nil : trimmedEditedDescription
        goal.isCompleted = editedIsCompleted
        isEditing = false
    }
}

#Preview("Incomplete Goal") {
    NavigationStack {
        GoalDetailView(
            goal: .constant(Goal(
                name: "Run a 5K",
                description: "Build up endurance with three runs per week.",
                createdAt: Date(),
                isCompleted: false,
            )),
            onDelete: {},
        )
    }
}

#Preview("Completed Goal") {
    NavigationStack {
        GoalDetailView(
            goal: .constant(Goal(
                name: "Read every night",
                description: "Read for at least 20 minutes before bed.",
                createdAt: Date(),
                isCompleted: true,
            )),
            onDelete: {},
        )
    }
}
