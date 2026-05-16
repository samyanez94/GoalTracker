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

struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var model: GoalFormModel

    @FocusState private var isTextInputFocused: Bool

    @State private var saveFailure: GoalSaveFailure?

    private let mode: GoalFormMode

    private let onSave: (GoalFormData) throws -> Void

    init(
        mode: GoalFormMode,
        onSave: @escaping (GoalFormData) throws -> Void,
    ) {
        self.mode = mode
        self.onSave = onSave
        _model = State(initialValue: GoalFormModel(mode: mode))
    }

    var body: some View {
        // The view owns the form model with @State; @Bindable exposes bindings to its fields.
        @Bindable var model = model

        Form {
            Section("Details") {
                TextField("Goal name", text: $model.name)
                    .focused($isTextInputFocused)
                TextField(
                    "Description",
                    text: $model.details,
                    axis: .vertical,
                )
                .focused($isTextInputFocused)
                .lineLimit(1...6)
            }
            Section {
                HStack {
                    DueDateSummaryButton(
                        hasDueDate: model.hasDueDate,
                        dueDate: model.dueDate,
                        action: {
                            withAnimation {
                                model.toggleDueDatePicker()
                            }
                        },
                    )
                    Toggle(
                        "Due Date",
                        isOn: $model.hasDueDate,
                    )
                    .labelsHidden()
                }
                if model.hasDueDate, model.isDueDatePickerExpanded {
                    DatePicker(
                        "Select due date",
                        selection: $model.dueDate,
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
                Toggle("Track progress", isOn: $model.isProgressBased)
                if model.isProgressBased {
                    ProgressTextFieldRow(
                        label: "Current",
                        placeholder: "0",
                        value: $model.currentValue,
                        focus: $isTextInputFocused,
                    )
                    ProgressTextFieldRow(
                        label: "Target",
                        placeholder: "1",
                        value: $model.targetValue,
                        focus: $isTextInputFocused,
                    )
                    ProgressTextFieldRow(
                        label: "Step",
                        placeholder: "1",
                        value: $model.step,
                        focus: $isTextInputFocused,
                    )
                    NavigationLink(value: GoalFormDestination.progressUnit) {
                        HStack {
                            Text("Unit")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(model.selectedProgressUnit?.title ?? "None")
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
                    .disabled(model.isSaveDisabled)
                    .opacity(model.isSaveDisabled ? 0.5 : 1)
            }
        }
        .onChange(of: model.hasDueDate) { _, hasDueDate in
            isTextInputFocused = false
            withAnimation {
                model.setDueDateEnabled(hasDueDate)
            }
        }
        .onChange(of: model.isProgressBased) {
            isTextInputFocused = false
        }
        .navigationDestination(for: GoalFormDestination.self) { destination in
            switch destination {
            case .progressUnit:
                ProgressUnitSelectionView(selectedUnit: $model.selectedProgressUnit)
            }
        }
        .goalSaveFailureAlert(failure: $saveFailure)
    }

    private func save() {
        guard !model.isSaveDisabled else {
            return
        }
        do {
            try onSave(model.makeFormData())
            dismiss()
        } catch {
            saveFailure = model.saveFailureKind
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
