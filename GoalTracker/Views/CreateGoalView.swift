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

    @State private var isQuantified = false

    @State private var initialValue = ""

    @State private var targetValue = ""

    let onSave: (_ name: String, _ description: String?, _ kind: Goal.Kind, _ progress: Goal.Progress) -> Void

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
        if !isQuantified {
            return trimmedName.isEmpty
        }
        guard parsedInitialValue != nil, let parsedTargetValue else {
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
                .lineLimit(1 ... 6)
            }
            Section("Progress") {
                Toggle("Progress-based goal", isOn: $isQuantified)

                Text("A goal you complete over time by making measurable progress.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if isQuantified {
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
        let kind: Goal.Kind
        let progress: Goal.Progress

        if isQuantified {
            guard let parsedInitialValue,
                    let parsedTargetValue else {
                return
            }
            kind = .quantified
            progress = Goal.Progress(
                currentValue: parsedInitialValue,
                targetValue: parsedTargetValue,
            )
        } else {
            kind = .outcome
            progress = Goal.Progress(
                currentValue: 0,
                targetValue: 1,
            )
        }
        onSave(
            trimmedName,
            trimmedDescription.isEmpty ? nil : trimmedDescription,
            kind, progress
        )
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CreateGoalView { _, _, _, _ in }
    }
}
