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
    var dueDate: Date?
    var completion: Goal.Completion

    static let empty = GoalFormData(
        name: "",
        description: "",
        dueDate: nil,
        completion: .outcome(isCompleted: false),
    )

    init(goal: Goal) {
        name = goal.name
        description = goal.description ?? ""
        dueDate = goal.dueDate
        completion = goal.completion
    }

    init(
        name: String,
        description: String,
        dueDate: Date? = nil,
        completion: Goal.Completion,
    ) {
        self.name = name
        self.description = description
        self.dueDate = dueDate
        self.completion = completion
    }

    var normalizedDescription: String? {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedDescription.isEmpty ? nil : trimmedDescription
    }
}

private struct InitialState {
    var name: String
    var description: String
    var hasDueDate: Bool
    var dueDate: Date
    var isDueDatePickerExpanded: Bool
    var isProgressBased: Bool
    var currentValue: String
    var targetValue: String
    var incrementValue: String
    var selectedProgressUnit: GoalProgressUnit?
    var outcomeIsCompleted: Bool
}

struct GoalFormView: View {
    enum Mode {
        case create
        case edit(GoalFormData)

        var title: String {
            switch self {
            case .create:
                "New Goal"
            case .edit:
                "Edit Goal"
            }
        }

        var initialData: GoalFormData {
            switch self {
            case .create:
                .empty
            case let .edit(data):
                data
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var name: String

    @State private var description: String

    @State private var hasDueDate: Bool

    @State private var dueDate: Date

    @State private var isDueDatePickerExpanded: Bool

    @State private var isProgressBased: Bool

    @State private var currentValue: String

    @State private var targetValue: String

    @State private var incrementValue: String

    @State private var selectedProgressUnit: GoalProgressUnit?

    @FocusState private var isTextInputFocused: Bool

    private let mode: Mode

    private let initialOutcomeIsCompleted: Bool

    private let onSave: (GoalFormData) -> Void

    init(
        mode: Mode,
        onSave: @escaping (GoalFormData) -> Void,
    ) {
        self.mode = mode
        self.onSave = onSave
        let initialState = Self.initialState(for: mode.initialData)
        initialOutcomeIsCompleted = initialState.outcomeIsCompleted
        _name = State(initialValue: initialState.name)
        _description = State(initialValue: initialState.description)
        _hasDueDate = State(initialValue: initialState.hasDueDate)
        _dueDate = State(initialValue: initialState.dueDate)
        _isDueDatePickerExpanded = State(initialValue: initialState.isDueDatePickerExpanded)
        _isProgressBased = State(initialValue: initialState.isProgressBased)
        _currentValue = State(initialValue: initialState.currentValue)
        _targetValue = State(initialValue: initialState.targetValue)
        _incrementValue = State(initialValue: initialState.incrementValue)
        _selectedProgressUnit = State(initialValue: initialState.selectedProgressUnit)
    }

    private static func initialState(for data: GoalFormData) -> InitialState {
        switch data.completion {
        case let .progress(progress):
            InitialState(
                name: data.name,
                description: data.description,
                hasDueDate: data.dueDate != nil,
                dueDate: data.dueDate ?? Date(),
                isDueDatePickerExpanded: false,
                isProgressBased: true,
                currentValue: text(for: progress.currentValue),
                targetValue: text(for: progress.targetValue),
                incrementValue: text(for: progress.incrementValue),
                selectedProgressUnit: progress.unit,
                outcomeIsCompleted: data.completion.isCompleted,
            )
        case .outcome:
            InitialState(
                name: data.name,
                description: data.description,
                hasDueDate: data.dueDate != nil,
                dueDate: data.dueDate ?? Date(),
                isDueDatePickerExpanded: false,
                isProgressBased: false,
                currentValue: "",
                targetValue: "",
                incrementValue: "1",
                selectedProgressUnit: nil,
                outcomeIsCompleted: data.completion.isCompleted,
            )
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

    private var parsedProgressValues: (
        currentValue: Double,
        targetValue: Double,
        incrementValue: Double,
    )? {
        guard let parsedCurrentValue,
              let parsedTargetValue,
              let parsedIncrementValue
        else {
            return nil
        }
        return (parsedCurrentValue, parsedTargetValue, parsedIncrementValue)
    }

    private var hasValidProgressValues: Bool {
        guard let parsedProgressValues else {
            return false
        }
        return Goal.Progress.isValid(
            currentValue: parsedProgressValues.currentValue,
            targetValue: parsedProgressValues.targetValue,
            incrementValue: parsedProgressValues.incrementValue,
        )
    }

    private var progressStartsIncomplete: Bool {
        guard let parsedProgressValues else {
            return false
        }
        return parsedProgressValues.currentValue < parsedProgressValues.targetValue
    }

    private var isSaveDisabled: Bool {
        guard !trimmedName.isEmpty else {
            return true
        }
        guard isProgressBased else {
            return false
        }
        guard hasValidProgressValues else {
            return true
        }
        switch mode {
        case .create:
            return !progressStartsIncomplete
        case .edit:
            return false
        }
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Goal name", text: $name)
                    .focused($isTextInputFocused)
                TextField(
                    "Description",
                    text: $description,
                    axis: .vertical,
                )
                .focused($isTextInputFocused)
                .lineLimit(1 ... 6)
            }
            Section {
                HStack {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Due Date")
                            if hasDueDate {
                                Text(GoalDueDateFormatter.string(from: dueDate))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleDueDatePicker()
                    }
                    Toggle(
                        "Due Date",
                        isOn: $hasDueDate,
                    )
                    .labelsHidden()
                }
                if hasDueDate, isDueDatePickerExpanded {
                    DatePicker(
                        "Select due date",
                        selection: $dueDate,
                        displayedComponents: .date,
                    )
                    .datePickerStyle(.graphical)
                }
            } footer: {
                Text("Set a due date to help you know when to complete this goal.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section {
                Toggle("Track progress", isOn: $isProgressBased)
                if isProgressBased {
                    progressTextFieldRow(
                        label: "Current",
                        value: $currentValue,
                    )
                    progressTextFieldRow(
                        label: "Target",
                        value: $targetValue,
                    )
                    progressTextFieldRow(
                        label: "Step",
                        value: $incrementValue,
                    )
                    NavigationLink {
                        ProgressUnitSelectionView(selectedUnit: $selectedProgressUnit)
                    } label: {
                        HStack {
                            Text("Unit")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(selectedProgressUnit?.title ?? "None")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Progress")
            } footer: {
                Text("Track progress toward a numeric target.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(mode.title)
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
        .onChange(of: hasDueDate) { _, hasDueDate in
            isTextInputFocused = false
            withAnimation {
                isDueDatePickerExpanded = hasDueDate
            }
        }
        .onChange(of: isProgressBased) {
            isTextInputFocused = false
        }
    }

    private func progressTextFieldRow(label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
            TextField("0", text: value)
                .focused($isTextInputFocused)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func toggleDueDatePicker() {
        guard hasDueDate else {
            return
        }
        withAnimation {
            isDueDatePickerExpanded.toggle()
        }
    }

    private func save() {
        guard !isSaveDisabled else {
            return
        }
        let completion: Goal.Completion

        if isProgressBased {
            guard let parsedProgressValues else {
                return
            }
            completion = .progress(
                Goal.Progress(
                    currentValue: parsedProgressValues.currentValue,
                    targetValue: parsedProgressValues.targetValue,
                    incrementValue: parsedProgressValues.incrementValue,
                    unit: selectedProgressUnit,
                ),
            )
        } else {
            completion = .outcome(isCompleted: initialOutcomeIsCompleted)
        }
        onSave(
            GoalFormData(
                name: trimmedName,
                description: description,
                dueDate: hasDueDate ? dueDate : nil,
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
        GoalFormView(mode: .create) { _ in }
    }
}

#Preview("Edit") {
    NavigationStack {
        GoalFormView(
            mode: .edit(
                GoalFormData(
                    name: "Workout 10 times",
                    description: "Move a little every day.",
                    dueDate: Date(),
                    completion: .progress(
                        Goal.Progress(currentValue: 3, targetValue: 10, incrementValue: 2),
                    ),
                ),
            ),
        ) { _ in }
    }
}
