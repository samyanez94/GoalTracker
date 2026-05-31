//
//  GoalFormModel.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/15/26.
//

import Foundation
import Observation

/// Keeps track of the editable state for the form.
///
/// The view binds to this model while the model handles validation, save data, and dirty-state checks.
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
	private var initialSnapshot = GoalFormSnapshot.empty
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

		initialSnapshot = currentSnapshot
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

	var hasChanges: Bool {
		currentSnapshot != initialSnapshot
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

	private var currentSnapshot: GoalFormSnapshot {
		GoalFormSnapshot(
			name: trimmedName,
			details: details,
			dueDate: allowsDueDate && hasDueDate ? dueDate : nil,
			reminder: recurrence != nil || hasDueDate ? reminder : nil,
			recurrence: recurrence,
			isProgressBased: isProgressBased,
			targetValue: isProgressBased ? targetValue : nil,
			step: isProgressBased ? step : nil,
			progressUnitId: isProgressBased ? selectedProgressUnit?.id : nil,
			tagIds: selectedTags.map(\.id.uuidString).sorted(),
		)
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

/// A normalized representation of the form's save data.
///
/// This snapshot is used to detect unsaved changes in the form.
private struct GoalFormSnapshot: Equatable {
	var name: String
	var details: String
	var dueDate: Date?
	var reminder: GoalReminder?
	var recurrence: GoalRecurrence?
	var isProgressBased: Bool
	var targetValue: Double?
	var step: Double?
	var progressUnitId: String?
	var tagIds: [String]

	static let empty = GoalFormSnapshot(
		name: "",
		details: "",
		dueDate: nil,
		reminder: nil,
		recurrence: nil,
		isProgressBased: false,
		targetValue: nil,
		step: nil,
		progressUnitId: nil,
		tagIds: [],
	)
}
