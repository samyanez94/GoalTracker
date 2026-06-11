//
//  GoalFormProgressState.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/3/26.
//

import Foundation

/// Keeps track of progress draft state for the goal form.
struct GoalFormProgressState {
	var kind: Kind
	var targetValue: Double?
	var step: Double?
	var selectedUnit: GoalProgressUnit?

	private let initialOutcomeIsCompleted: Bool

	init(progress: GoalProgress) {
		initialOutcomeIsCompleted = progress.isCompleted
		switch progress {
		case .measurable(let progress):
			kind = .measurable
			targetValue = progress.targetValue
			step = progress.step
			selectedUnit = progress.unit
		case .outcome:
			kind = .outcome
			targetValue = nil
			step = nil
			selectedUnit = nil
		}
	}

	var isProgressBased: Bool {
		get {
			kind == .measurable
		}
		set {
			kind = newValue ? .measurable : .outcome
		}
	}

	var isSaveValid: Bool {
		guard isProgressBased else {
			return true
		}
		return MeasurableProgress.isValid(
			currentValue: .zero,
			targetValue: targetValue ?? 1,
			step: step ?? 1,
		)
	}

	var snapshot: Snapshot {
		Snapshot(
			isProgressBased: isProgressBased,
			targetValue: isProgressBased ? targetValue : nil,
			step: isProgressBased ? step : nil,
			progressUnitId: isProgressBased ? selectedUnit?.id : nil,
		)
	}

	func makeProgress(timestamp: Date) -> GoalProgress {
		if isProgressBased {
			return .measurable(
				currentValue: .zero,
				targetValue: targetValue ?? 1,
				step: step ?? 1,
				unit: selectedUnit,
				timestamp: timestamp,
			)
		}
		if initialOutcomeIsCompleted {
			return .outcome(OutcomeProgress.completed(timestamp: timestamp))
		}
		return .outcome(OutcomeProgress())
	}

	enum Kind {
		case outcome
		case measurable
	}

	struct Snapshot: Equatable {
		var isProgressBased: Bool
		var targetValue: Double?
		var step: Double?
		var progressUnitId: String?

		static func == (lhs: Snapshot, rhs: Snapshot) -> Bool {
			lhs.isProgressBased == rhs.isProgressBased
				&& lhs.targetValue == rhs.targetValue
				&& lhs.step == rhs.step
				&& lhs.progressUnitId == rhs.progressUnitId
		}
	}
}
