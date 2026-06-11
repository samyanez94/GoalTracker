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
	var schedule: GoalFormScheduleState
	var progress: GoalFormProgressState
	var tagSelections: [GoalFormTagSelection]

	let mode: GoalFormMode

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
		schedule = GoalFormScheduleState(
			targetDate: data.targetDate,
			reminder: data.reminder,
			recurrence: data.recurrence,
			defaultTargetDate: now(),
		)
		progress = GoalFormProgressState(progress: data.progress)
		tagSelections = data.tags

		initialSnapshot = currentSnapshot
	}

	var isSaveDisabled: Bool {
		guard !trimmedName.isEmpty else {
			return true
		}
		guard progress.isSaveValid else {
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

	func makeFormData() -> GoalFormData {
		GoalFormData(
			name: trimmedName,
			details: details,
			targetDate: schedule.formTargetDate,
			reminder: schedule.formReminder,
			progress: progress.makeProgress(timestamp: now()),
			recurrence: schedule.recurrence,
			tags: selectedTagSelections,
		)
	}

	private var trimmedName: String {
		name.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private var normalizedDetails: String? {
		let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
		return trimmedDetails.isEmpty ? nil : trimmedDetails
	}

	private var currentSnapshot: GoalFormSnapshot {
		GoalFormSnapshot(
			name: trimmedName,
			details: normalizedDetails,
			schedule: schedule.snapshot,
			progress: progress.snapshot,
			tagNames: Set(selectedTagSelections.map(\.normalizedName)),
		)
	}

	private var selectedTagSelections: [GoalFormTagSelection] {
		tagSelections.filter(\.isSelected)
	}
}

// MARK: - GoalFormSnapshot

/// A normalized representation of the form's save data.
///
/// This snapshot is used to detect unsaved changes in the form.
private struct GoalFormSnapshot: Equatable {
	var name: String
	var details: String?
	var schedule: GoalFormScheduleState.Snapshot
	var progress: GoalFormProgressState.Snapshot
	var tagNames: Set<String>

	static func == (lhs: GoalFormSnapshot, rhs: GoalFormSnapshot) -> Bool {
		lhs.name == rhs.name
			&& lhs.details == rhs.details
			&& lhs.schedule == rhs.schedule
			&& lhs.progress == rhs.progress
			&& lhs.tagNames == rhs.tagNames
	}

	static let empty = GoalFormSnapshot(
		name: "",
		details: nil,
		schedule: GoalFormScheduleState.Snapshot(
			targetDate: nil,
			reminder: nil,
			recurrence: nil,
		),
		progress: GoalFormProgressState.Snapshot(
			isProgressBased: false,
			targetValue: nil,
			step: nil,
			progressUnitId: nil,
		),
		tagNames: [],
	)
}
