//
//  GoalFormModel.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/15/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class GoalFormModel {
    var name: String
    var details: String
    var hasDueDate: Bool
    var dueDate: Date
    var isDueDatePickerExpanded = false
    var isProgressBased: Bool
    var currentValue: Double
    var targetValue: Double
    var step: Double
    var selectedProgressUnit: GoalProgressUnit?

    private let mode: GoalFormMode
    private let initialOutcomeIsCompleted: Bool

    init(mode: GoalFormMode) {
        self.mode = mode
        let data = mode.initialData
        name = data.name
        details = data.details
        hasDueDate = data.dueDate != nil
        dueDate = data.dueDate ?? Date()
        initialOutcomeIsCompleted = data.progress.isCompleted

        switch data.progress.kind {
        case .measurable:
            isProgressBased = true
            currentValue = data.progress.currentValue
            targetValue = data.progress.targetValue
            step = data.progress.step
            selectedProgressUnit = data.progress.unit
        case .outcome:
            isProgressBased = false
            currentValue = 0
            targetValue = 1
            step = 1
            selectedProgressUnit = nil
        }
    }

    var isSaveDisabled: Bool {
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

    var saveFailureKind: GoalSaveFailure {
        switch mode {
        case .create:
            .addGoal
        case .edit:
            .updateGoal
        }
    }

    func toggleDueDatePicker() {
        guard hasDueDate else {
            return
        }
        isDueDatePickerExpanded.toggle()
    }

    func setDueDateEnabled(_ isEnabled: Bool) {
        isDueDatePickerExpanded = isEnabled
    }

    func makeFormData() -> GoalFormData {
        GoalFormData(
            name: trimmedName,
            details: details,
            dueDate: hasDueDate ? dueDate : nil,
            progress: progress,
        )
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

    private var progress: GoalProgress {
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
    }
}
