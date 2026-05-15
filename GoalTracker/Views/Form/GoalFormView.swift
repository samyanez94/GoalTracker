//
//  GoalFormView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/3/26.
//

import SwiftUI

enum GoalFormMode {
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
        case .edit(let data):
            data
        }
    }
}

private enum GoalFormDestination: Hashable {
    case progressUnit
}

private struct GoalFormInitialState {
    var name: String
    var details: String
    var hasDueDate: Bool
    var dueDate: Date
    var isDueDatePickerExpanded: Bool
    var isProgressBased: Bool
    var currentValue: Double
    var targetValue: Double
    var step: Double
    var selectedProgressUnit: GoalProgressUnit?
    var outcomeIsCompleted: Bool
}

struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String

    @State private var details: String

    @State private var hasDueDate: Bool

    @State private var dueDate: Date

    @State private var isDueDatePickerExpanded: Bool

    @State private var isProgressBased: Bool

    @State private var currentValue: Double

    @State private var targetValue: Double

    @State private var step: Double

    @State private var selectedProgressUnit: GoalProgressUnit?

    @FocusState private var isTextInputFocused: Bool

    @State private var saveFailure: GoalSaveFailure?

    private let mode: GoalFormMode

    private let initialOutcomeIsCompleted: Bool

    private let onSave: (GoalFormData) throws -> Void

    init(
        mode: GoalFormMode,
        onSave: @escaping (GoalFormData) throws -> Void,
    ) {
        self.mode = mode
        self.onSave = onSave
        let initialState = Self.initialState(for: mode.initialData)
        initialOutcomeIsCompleted = initialState.outcomeIsCompleted
        _name = State(initialValue: initialState.name)
        _details = State(initialValue: initialState.details)
        _hasDueDate = State(initialValue: initialState.hasDueDate)
        _dueDate = State(initialValue: initialState.dueDate)
        _isDueDatePickerExpanded = State(initialValue: initialState.isDueDatePickerExpanded)
        _isProgressBased = State(initialValue: initialState.isProgressBased)
        _currentValue = State(initialValue: initialState.currentValue)
        _targetValue = State(initialValue: initialState.targetValue)
        _step = State(initialValue: initialState.step)
        _selectedProgressUnit = State(initialValue: initialState.selectedProgressUnit)
    }

    private static func initialState(for data: GoalFormData) -> GoalFormInitialState {
        switch data.progress.kind {
        case .measurable:
            GoalFormInitialState(
                name: data.name,
                details: data.details,
                hasDueDate: data.dueDate != nil,
                dueDate: data.dueDate ?? Date(),
                isDueDatePickerExpanded: false,
                isProgressBased: true,
                currentValue: data.progress.currentValue,
                targetValue: data.progress.targetValue,
                step: data.progress.step,
                selectedProgressUnit: data.progress.unit,
                outcomeIsCompleted: data.progress.isCompleted,
            )
        case .outcome:
            GoalFormInitialState(
                name: data.name,
                details: data.details,
                hasDueDate: data.dueDate != nil,
                dueDate: data.dueDate ?? Date(),
                isDueDatePickerExpanded: false,
                isProgressBased: false,
                currentValue: 0,
                targetValue: 1,
                step: 1,
                selectedProgressUnit: nil,
                outcomeIsCompleted: data.progress.isCompleted,
            )
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasValidProgressValues: Bool {
        GoalProgress.isValid(
            currentValue: currentValue,
            targetValue: targetValue,
            step: step,
        )
    }

    private var progressStartsIncomplete: Bool {
        currentValue < targetValue
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
                    text: $details,
                    axis: .vertical,
                )
                .focused($isTextInputFocused)
                .lineLimit(1...6)
            }
            Section {
                HStack {
                    DueDateSummaryButton(
                        hasDueDate: hasDueDate,
                        dueDate: dueDate,
                        action: toggleDueDatePicker,
                    )
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
                    ProgressTextFieldRow(
                        label: "Current",
                        value: $currentValue,
                        focus: $isTextInputFocused,
                    )
                    ProgressTextFieldRow(
                        label: "Target",
                        value: $targetValue,
                        focus: $isTextInputFocused,
                    )
                    ProgressTextFieldRow(
                        label: "Step",
                        value: $step,
                        focus: $isTextInputFocused,
                    )
                    NavigationLink(value: GoalFormDestination.progressUnit) {
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
                Button("Cancel", systemImage: "xmark") {
                    dismiss()
                }
                .labelStyle(.iconOnly)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", systemImage: "checkmark", action: save)
                    .labelStyle(.iconOnly)
                    .tint(.blue)
                    .buttonStyle(.glassProminent)
                    .disabled(isSaveDisabled)
                    .opacity(isSaveDisabled ? 0.5 : 1)
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
        .navigationDestination(for: GoalFormDestination.self) { destination in
            switch destination {
            case .progressUnit:
                ProgressUnitSelectionView(selectedUnit: $selectedProgressUnit)
            }
        }
        .goalSaveFailureAlert(failure: $saveFailure)
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
        let progress: GoalProgress =
            if isProgressBased {
                .measurable(
                    currentValue: currentValue,
                    targetValue: targetValue,
                    step: step,
                    unit: selectedProgressUnit,
                )
            } else {
                initialOutcomeIsCompleted ? .outcomeCompleted : .outcomePending
            }
        do {
            try onSave(
                GoalFormData(
                    name: trimmedName,
                    details: details,
                    dueDate: hasDueDate ? dueDate : nil,
                    progress: progress,
                ),
            )
            dismiss()
        } catch {
            saveFailure = saveFailureKind
        }
    }

    private var saveFailureKind: GoalSaveFailure {
        switch mode {
        case .create:
            .addGoal
        case .edit:
            .updateGoal
        }
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
                    details: "Move a little every day.",
                    dueDate: Date(),
                    progress: .measurable(currentValue: 3, targetValue: 10, step: 2),
                ),
            ),
        ) { _ in }
    }
}
