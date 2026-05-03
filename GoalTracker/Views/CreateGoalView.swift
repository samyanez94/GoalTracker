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

    @State private var initialValue = ""

    @State private var targetValue = ""

    let onSave: (_ name: String, _ description: String?, _ progress: Goal.Progress) -> Void

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDescription: String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedInitialValue: Double? {
        Double(initialValue)
    }

    private var parsedTargetValue: Double? {
        Double(targetValue)
    }

    private var isSaveDisabled: Bool {
        guard parsedInitialValue != nil,
                let parsedTargetValue else {
            return true
        }
        return trimmedName.isEmpty || parsedTargetValue <= 0
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Goal name", text: $name)
                TextField(
                    "Description (optional)",
                    text: $description,
                    axis: .vertical,
                )
                .lineLimit(3 ... 6)
            }
            Section("Progress") {
                HStack {
                    Text("Initial value")
                        .foregroundStyle(.secondary)
                    TextField("0", text: $initialValue)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Target value")
                        .foregroundStyle(.secondary)
                    TextField("100", text: $targetValue)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
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
                .disabled(isSaveDisabled)
            }
        }
    }

    private func saveGoal() {
        guard let parsedInitialValue,
                let parsedTargetValue else {
            return
        }
        let progress = Goal.Progress(
            currentValue: parsedInitialValue,
            targetValue: parsedTargetValue,
        )
        onSave(trimmedName, trimmedDescription.isEmpty ? nil : trimmedDescription, progress)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CreateGoalView { _, _, _ in }
    }
}
