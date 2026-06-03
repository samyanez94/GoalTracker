//
//  GoalFormState.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/15/26.
//

import Foundation
import Observation

// MARK: - GoalFormState

/// Keeps track of draft values and form behavior state.
///
/// The view binds to this state while it handles validation, save data, and dirty-state checks. Presentation-only state, such as confirmation dialogs and focus, stays in the view.
@MainActor
@Observable
final class GoalFormState {
	var name: String
	var details: String
	var hasTargetDate: Bool
	var targetDate: Date
	var reminder: GoalReminder?
	var isTargetDatePickerExpanded = false
	var isProgressBased: Bool
	var targetValue: Double = 1
	var step: Double = 1
	var selectedProgressUnit: GoalProgressUnit?

	var recurrence: GoalRecurrence? {
		didSet {
			clearTargetDateIfNeededForRecurrence()
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
		hasTargetDate = data.targetDate != nil && data.recurrence == nil
		targetDate = data.targetDate ?? Date()
		reminder = data.reminder
		recurrence = data.recurrence
		selectedTags = data.tags
		initialOutcomeIsCompleted = data.progress.isCompleted

		switch data.progress {
		case .measurable(let progress):
			isProgressBased = true
			targetValue = progress.targetValue
			step = progress.step
			selectedProgressUnit = progress.unit
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

	var allowsTargetDate: Bool {
		recurrence == nil
	}

	func toggleTargetDatePicker() {
		guard hasTargetDate else {
			return
		}
		isTargetDatePickerExpanded.toggle()
	}

	func setTargetDateEnabled(_ isEnabled: Bool) {
		isTargetDatePickerExpanded = isEnabled
		if !isEnabled, recurrence == nil {
			reminder = nil
		}
	}

	func makeFormData() -> GoalFormData {
		GoalFormData(
			name: trimmedName,
			details: details,
			targetDate: allowsTargetDate && hasTargetDate ? targetDate : nil,
			reminder: recurrence != nil || hasTargetDate ? reminder : nil,
			progress: progress,
			recurrence: recurrence,
			tags: selectedTags,
		)
	}

	private func clearTargetDateIfNeededForRecurrence() {
		guard recurrence != nil else {
			return
		}
		hasTargetDate = false
		isTargetDatePickerExpanded = false
	}

	private var trimmedName: String {
		name.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private var currentSnapshot: GoalFormSnapshot {
		GoalFormSnapshot(
			name: trimmedName,
			details: details,
			targetDate: allowsTargetDate && hasTargetDate ? targetDate : nil,
			reminder: recurrence != nil || hasTargetDate ? reminder : nil,
			recurrence: recurrence,
			isProgressBased: isProgressBased,
			targetValue: isProgressBased ? targetValue : nil,
			step: isProgressBased ? step : nil,
			progressUnitId: isProgressBased ? selectedProgressUnit?.id : nil,
			tagIds: selectedTags.map(\.id.uuidString).sorted(),
		)
	}

	private var hasValidProgressValues: Bool {
		return MeasurableProgress.isValid(
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
		}
		if initialOutcomeIsCompleted {
			return .outcome(OutcomeProgress.completed(timestamp: now()))
		}
		return .outcome(OutcomeProgress())
	}
}

// MARK: - GoalFormSnapshot

/// A normalized representation of the form's save data.
///
/// This snapshot is used to detect unsaved changes in the form.
private struct GoalFormSnapshot: Equatable {
	var name: String
	var details: String
	var targetDate: Date?
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
		targetDate: nil,
		reminder: nil,
		recurrence: nil,
		isProgressBased: false,
		targetValue: nil,
		step: nil,
		progressUnitId: nil,
		tagIds: [],
	)
}
