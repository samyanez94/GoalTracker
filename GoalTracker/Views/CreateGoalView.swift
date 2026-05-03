//
//  CreateGoalView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftUI

struct CreateGoalView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""

    @State private var description = ""

    let onSave: (Goal) -> Void

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDescription: String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section {
                TextField("Goal name", text: $name)
                TextField(
                    "Description (optional)",
                    text: $description,
                    axis: .vertical,
                )
                .lineLimit(3 ... 6)
            }
        }
        .navigationTitle("New Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveGoal()
                }
                .disabled(trimmedName.isEmpty)
            }
        }
    }

    private func saveGoal() {
        let goal = Goal(
            name: trimmedName,
            description: trimmedDescription.isEmpty ? nil : trimmedDescription,
            createdAt: Date(),
            isCompleted: false,
        )
        onSave(goal)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CreateGoalView { _ in }
    }
}
