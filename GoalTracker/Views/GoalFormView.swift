//
//  GoalFormView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/3/26.
//

import SwiftUI

struct GoalFormData {
    var name: String
    var description: String
    var kind: Goal.Kind
    var progress: Goal.Progress

    static let empty = GoalFormData(
        name: "",
        description: "",
        kind: .outcome,
        progress: Goal.Progress(currentValue: 0, targetValue: 1),
    )

    init(goal: Goal) {
        self.name = goal.name
        self.description = goal.description ?? ""
        self.kind = goal.kind
        self.progress = goal.progress
    }

    init(
        name: String,
        description: String,
        kind: Goal.Kind,
        progress: Goal.Progress,
    ) {
        self.name = name
        self.description = description
        self.kind = kind
        self.progress = progress
    }

    var normalizedDescription: String? {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedDescription.isEmpty ? nil : trimmedDescription
    }
}

struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String

    @State private var description: String

    @State private var isQuantified: Bool

    @State private var currentValue: String

    @State private var targetValue: String

    @State private var incrementValue: String

    private let title: String

    private let initialOutcomeCurrentValue: Double

    private let onSave: (GoalFormData) -> Void

    init(
        title: String,
        initialData: GoalFormData = .empty,
        onSave: @escaping (GoalFormData) -> Void,
    ) {
        self.title = title
        self.initialOutcomeCurrentValue = initialData.progress.isCompleted ? 1 : 0
        self.onSave = onSave
        _name = State(initialValue: initialData.name)
        _description = State(initialValue: initialData.description)
        _isQuantified = State(initialValue: initialData.kind == .quantified)
        _currentValue = State(initialValue: Self.text(for: initialData.progress.currentValue))
        _targetValue = State(initialValue: Self.text(for: initialData.progress.targetValue))
        _incrementValue = State(initialValue: Self.text(for: initialData.progress.incrementValue))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedCurrentValue: Double? {
        Double(currentValue)
    }

    private var parsedTargetValue: Double? {
        Double(targetValue)
    }

    private var parsedIncrementValue: Double? {
        Double(incrementValue)
    }

    private var isSaveDisabled: Bool {
        if !isQuantified {
            return trimmedName.isEmpty
        }
        guard parsedCurrentValue != nil,
              let parsedTargetValue,
              let parsedIncrementValue else {
            return true
        }

        return trimmedName.isEmpty || parsedTargetValue <= 0 || parsedIncrementValue <= 0
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
                    progressTextFieldRow(label: "Current value", value: $currentValue)
                    progressTextFieldRow(label: "Target value", value: $targetValue)
                    progressTextFieldRow(label: "Increment", value: $incrementValue)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Cancel")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    save()
                } label: {
                    Image(systemName: "checkmark")
                }
                .tint(.blue)
                .buttonStyle(.glassProminent)
                .disabled(isSaveDisabled)
                .opacity(isSaveDisabled ? 0.5 : 1)
                .accessibilityLabel("Save")
            }
        }
    }

    private func progressTextFieldRow(label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func save() {
        let progress: Goal.Progress
        let kind: Goal.Kind

        if isQuantified {
            guard let parsedCurrentValue,
                  let parsedTargetValue,
                  let parsedIncrementValue else {
                return
            }
            kind = .quantified
            progress = Goal.Progress(
                currentValue: min(max(0, parsedCurrentValue), parsedTargetValue),
                targetValue: parsedTargetValue,
                incrementValue: parsedIncrementValue,
            )
        } else {
            kind = .outcome
            progress = Goal.Progress(
                currentValue: initialOutcomeCurrentValue,
                targetValue: 1,
                incrementValue: 1,
            )
        }
        onSave(
            GoalFormData(
                name: trimmedName,
                description: description,
                kind: kind,
                progress: progress,
            )
        )
        dismiss()
    }

    private static func text(for value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(value)
    }
}

#Preview("Create") {
    NavigationStack {
        GoalFormView(title: "New Goal") { _ in }
    }
}

#Preview("Edit") {
    NavigationStack {
        GoalFormView(
            title: "Edit Goal",
            initialData: GoalFormData(
                name: "Workout 10 times",
                description: "Move a little every day.",
                kind: .quantified,
                progress: Goal.Progress(currentValue: 3, targetValue: 10, incrementValue: 2),
            ),
        ) { _ in }
    }
}
