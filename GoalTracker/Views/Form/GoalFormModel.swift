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
    var reminder: GoalReminder?
    var isDueDatePickerExpanded = false
    var isProgressBased: Bool
    var targetValue: Double = 1
    var step: Double = 1
    var selectedProgressUnit: GoalProgressUnit?
    var recurrence: GoalRecurrence? {
        didSet {
            clearDueDateIfNeededForRecurrence()
        }
    }
    var selectedTags: [Tag]

    let mode: GoalFormMode
    private let initialOutcomeIsCompleted: Bool
    private let now: () -> Date

    init(
        mode: GoalFormMode,
        now: @escaping () -> Date = Date.init,
    ) {
        self.mode = mode
        self.now = now
        let data = mode.initialData
        name = data.name
        details = data.details
        hasDueDate = data.dueDate != nil && data.recurrence == nil
        dueDate = data.dueDate ?? Date()
        reminder = data.reminder
        recurrence = data.recurrence
        selectedTags = data.tags
        initialOutcomeIsCompleted = data.progress.isCompleted

        switch data.progress.kind {
        case .measurable:
            isProgressBased = true
            targetValue = data.progress.targetValue
            step = data.progress.step
            selectedProgressUnit = data.progress.unit
        case .outcome:
            isProgressBased = false
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
        return false
    }

    var saveFailureKind: GoalSaveFailure {
        switch mode {
        case .create:
            .addGoal
        case .edit:
            .updateGoal
        }
    }

    var allowsDueDate: Bool {
        recurrence == nil
    }

    func toggleDueDatePicker() {
        guard hasDueDate else {
            return
        }
        isDueDatePickerExpanded.toggle()
    }

    func setDueDateEnabled(_ isEnabled: Bool) {
        isDueDatePickerExpanded = isEnabled
        if !isEnabled, recurrence == nil {
            reminder = nil
        }
    }

    func makeFormData() -> GoalFormData {
        GoalFormData(
            name: trimmedName,
            details: details,
            dueDate: allowsDueDate && hasDueDate ? dueDate : nil,
            reminder: recurrence != nil || hasDueDate ? reminder : nil,
            progress: progress,
            recurrence: recurrence,
            tags: selectedTags,
        )
    }

    private func clearDueDateIfNeededForRecurrence() {
        guard recurrence != nil else {
            return
        }
        hasDueDate = false
        isDueDatePickerExpanded = false
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasValidProgressValues: Bool {
        return GoalProgress.isValid(
            currentValue: .zero,
            targetValue: targetValue,
            step: step,
        )
    }

    private var progress: GoalProgress {
        if isProgressBased {
            return .measurable(
                currentValue: .zero,
                targetValue: targetValue,
                step: step,
                unit: selectedProgressUnit,
                timestamp: now(),
            )
        } else {
            return initialOutcomeIsCompleted ? .outcomeCompleted : .outcomePending
        }
    }
}
