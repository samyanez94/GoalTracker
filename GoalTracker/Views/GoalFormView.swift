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
    var completion: Goal.Completion

    static let empty = GoalFormData(
        name: "",
        description: "",
        completion: .outcome(isCompleted: false),
    )

    init(goal: Goal) {
        name = goal.name
        description = goal.description ?? ""
        completion = goal.completion
    }

    init(
        name: String,
        description: String,
        completion: Goal.Completion,
    ) {
        self.name = name
        self.description = description
        self.completion = completion
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

    @State private var isProgressBased: Bool

    @State private var currentValue: String

    @State private var targetValue: String

    @State private var incrementValue: String

    private let title: String

    private let initialOutcomeIsCompleted: Bool

    private let onSave: (GoalFormData) -> Void

    init(
        title: String,
        initialData: GoalFormData = .empty,
        onSave: @escaping (GoalFormData) -> Void,
    ) {
        self.title = title
        initialOutcomeIsCompleted = initialData.completion.isCompleted
        self.onSave = onSave
        _name = State(initialValue: initialData.name)
        _description = State(initialValue: initialData.description)
        if case .progress(let progress) = initialData.completion {
            _isProgressBased = State(initialValue: true)
            _currentValue = State(initialValue: Self.text(for: progress.currentValue))
            _targetValue = State(initialValue: Self.text(for: progress.targetValue))
            _incrementValue = State(initialValue: Self.text(for: progress.incrementValue))
        } else {
            _isProgressBased = State(initialValue: false)
            _currentValue = State(initialValue: "0")
            _targetValue = State(initialValue: "1")
            _incrementValue = State(initialValue: "1")
        }
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
        if !isProgressBased {
            return trimmedName.isEmpty
        }
        guard parsedCurrentValue != nil,
              let parsedTargetValue,
              let parsedIncrementValue
        else {
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
            Section {
                Toggle("Progress-based goal", isOn: $isProgressBased)
                if isProgressBased {
                    progressTextFieldRow(
                        label: "Current value",
                        value: $currentValue,
                    )
                    progressTextFieldRow(
                        label: "Target value",
                        value: $targetValue,
                    )
                    progressTextFieldRow(
                        label: "Increment",
                        value: $incrementValue,
                    )
                }
            } header: {
                Text("Progress")
            } footer: {
                Text("A goal you complete over time by making measurable progress.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
        let completion: Goal.Completion

        if isProgressBased {
            guard let parsedCurrentValue,
                  let parsedTargetValue,
                  let parsedIncrementValue
            else {
                return
            }
            completion = .progress(
                Goal.Progress(
                    currentValue: min(max(0, parsedCurrentValue), parsedTargetValue),
                    targetValue: parsedTargetValue,
                    incrementValue: parsedIncrementValue,
                ),
            )
        } else {
            completion = .outcome(isCompleted: initialOutcomeIsCompleted)
        }
        onSave(
            GoalFormData(
                name: trimmedName,
                description: description,
                completion: completion,
            ),
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
                completion: .progress(
                    Goal.Progress(currentValue: 3, targetValue: 10, incrementValue: 2),
                ),
            ),
        ) { _ in }
    }
}
