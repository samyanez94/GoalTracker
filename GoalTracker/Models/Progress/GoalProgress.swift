//
//  GoalProgress.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation

// MARK: - GoalProgress

/// Describes how a goal tracks progress toward completion.
///
/// Each case owns only the state that applies to that goal type. Outcome goals are binary, while measurable goals advance toward a numeric target.
///
///  - Note: Progress history is stored as a single Codable value. In CloudKit sync edge cases, stale local writes may replace the full event array. Long-term fix: persist progress events as separate SwiftData records.
nonisolated enum GoalProgress: Codable, Equatable {

	/// Binary progress for goals that are either incomplete or complete.
	case outcome(OutcomeProgress = OutcomeProgress())

	/// Numeric progress for goals that advance toward a measurable target.
	case measurable(MeasurableProgress)

	/// Timestamped progress or completion changes for this goal.
	var events: [GoalProgressEvent] {
		switch self {
		case .outcome(let progress):
			progress.events
		case .measurable(let progress):
			progress.events
		}
	}

	/// The user's current progress toward completion.
	var currentValue: Double {
		switch self {
		case .outcome(let progress):
			progress.currentValue
		case .measurable(let progress):
			progress.currentValue
		}
	}

	/// Whether the goal has reached completion.
	var isCompleted: Bool {
		switch self {
		case .outcome(let progress):
			progress.isCompleted
		case .measurable(let progress):
			progress.isCompleted
		}
	}

	/// Whether this progress tracks a numeric value.
	var isMeasurable: Bool {
		if case .measurable = self {
			return true
		}
		return false
	}

	/// The outcome payload, when this progress tracks binary completion.
	var outcomeProgress: OutcomeProgress? {
		guard case .outcome(let progress) = self else {
			return nil
		}
		return progress
	}

	/// The measurable payload, when this progress tracks a numeric target.
	var measurableProgress: MeasurableProgress? {
		guard case .measurable(let progress) = self else {
			return nil
		}
		return progress
	}

	/// Whether there is progress available to subtract.
	var canDecrement: Bool {
		switch self {
		case .outcome:
			false
		case .measurable(let progress):
			progress.canDecrement
		}
	}

	/// Whether there is still room to add more progress.
	var canIncrement: Bool {
		switch self {
		case .outcome:
			false
		case .measurable(let progress):
			progress.canIncrement
		}
	}

	/// The progress amount represented from 0 to 1.
	var fractionCompleted: Double {
		switch self {
		case .outcome(let progress):
			progress.fractionCompleted
		case .measurable(let progress):
			progress.fractionCompleted
		}
	}

	static func measurable(
		currentValue: Double,
		targetValue: Double,
		step: Double = 1,
		unit: GoalProgressUnit? = nil,
		timestamp: Date = Date(),
	) -> GoalProgress {
		.measurable(
			MeasurableProgress(
				currentValue: currentValue,
				targetValue: targetValue,
				step: step,
				unit: unit,
				timestamp: timestamp,
			)
		)
	}

	@discardableResult
	mutating func complete(timestamp: Date = Date()) -> Bool {
		updateProgress(
			outcome: { $0.complete(timestamp: timestamp) },
			measurable: { $0.complete(timestamp: timestamp) },
		)
	}

	@discardableResult
	mutating func toggleCompletion(timestamp: Date = Date()) -> Bool {
		updateProgress(
			outcome: { $0.toggleCompletion(timestamp: timestamp) },
			measurable: { $0.toggleCompletion(timestamp: timestamp) },
		)
	}

	@discardableResult
	mutating func increment(timestamp: Date = Date()) -> Bool {
		updateMeasurableProgress { $0.increment(timestamp: timestamp) }
	}

	@discardableResult
	mutating func decrement(timestamp: Date = Date()) -> Bool {
		updateMeasurableProgress { $0.decrement(timestamp: timestamp) }
	}

	@discardableResult
	mutating func update(
		by amount: Double,
		timestamp: Date = Date(),
	) -> Bool {
		updateMeasurableProgress { $0.update(by: amount, timestamp: timestamp) }
	}

	func currentValue(in period: DateInterval) -> Double {
		switch self {
		case .outcome(let progress):
			progress.currentValue(in: period)
		case .measurable(let progress):
			progress.currentValue(in: period)
		}
	}

	func currentValue(in period: DateInterval?) -> Double {
		guard let period else {
			return currentValue
		}
		return currentValue(in: period)
	}

	func isCompleted(in period: DateInterval) -> Bool {
		switch self {
		case .outcome(let progress):
			progress.isCompleted(in: period)
		case .measurable(let progress):
			progress.isCompleted(in: period)
		}
	}

	func isCompleted(in period: DateInterval?) -> Bool {
		guard let period else {
			return isCompleted
		}
		return isCompleted(in: period)
	}

	func canDecrement(in period: DateInterval) -> Bool {
		switch self {
		case .outcome:
			false
		case .measurable(let progress):
			progress.canDecrement(in: period)
		}
	}

	func canDecrement(in period: DateInterval?) -> Bool {
		guard let period else {
			return canDecrement
		}
		return canDecrement(in: period)
	}

	func canIncrement(in period: DateInterval) -> Bool {
		switch self {
		case .outcome:
			false
		case .measurable(let progress):
			progress.canIncrement(in: period)
		}
	}

	func canIncrement(in period: DateInterval?) -> Bool {
		guard let period else {
			return canIncrement
		}
		return canIncrement(in: period)
	}

	@discardableResult
	mutating func complete(
		in period: DateInterval,
		timestamp: Date = Date(),
	) -> Bool {
		updateProgress(
			outcome: { $0.complete(in: period, timestamp: timestamp) },
			measurable: { $0.complete(in: period, timestamp: timestamp) },
		)
	}

	@discardableResult
	mutating func complete(
		in period: DateInterval?,
		timestamp: Date = Date(),
	) -> Bool {
		guard let period else {
			return complete(timestamp: timestamp)
		}
		return complete(in: period, timestamp: timestamp)
	}

	@discardableResult
	mutating func toggleCompletion(
		in period: DateInterval,
		timestamp: Date = Date(),
	) -> Bool {
		updateProgress(
			outcome: { $0.toggleCompletion(in: period, timestamp: timestamp) },
			measurable: { $0.toggleCompletion(in: period, timestamp: timestamp) },
		)
	}

	@discardableResult
	mutating func toggleCompletion(
		in period: DateInterval?,
		timestamp: Date = Date(),
	) -> Bool {
		guard let period else {
			return toggleCompletion(timestamp: timestamp)
		}
		return toggleCompletion(in: period, timestamp: timestamp)
	}

	@discardableResult
	mutating func increment(
		in period: DateInterval,
		timestamp: Date = Date(),
	) -> Bool {
		updateMeasurableProgress { $0.increment(in: period, timestamp: timestamp) }
	}

	@discardableResult
	mutating func increment(
		in period: DateInterval?,
		timestamp: Date = Date(),
	) -> Bool {
		guard let period else {
			return increment(timestamp: timestamp)
		}
		return increment(in: period, timestamp: timestamp)
	}

	@discardableResult
	mutating func decrement(
		in period: DateInterval,
		timestamp: Date = Date(),
	) -> Bool {
		updateMeasurableProgress { $0.decrement(in: period, timestamp: timestamp) }
	}

	@discardableResult
	mutating func decrement(
		in period: DateInterval?,
		timestamp: Date = Date(),
	) -> Bool {
		guard let period else {
			return decrement(timestamp: timestamp)
		}
		return decrement(in: period, timestamp: timestamp)
	}

	@discardableResult
	mutating func update(
		by amount: Double,
		in period: DateInterval,
		timestamp: Date = Date(),
	) -> Bool {
		updateMeasurableProgress { $0.update(by: amount, in: period, timestamp: timestamp) }
	}

	@discardableResult
	mutating func update(
		by amount: Double,
		in period: DateInterval?,
		timestamp: Date = Date(),
	) -> Bool {
		guard let period else {
			return update(by: amount, timestamp: timestamp)
		}
		return update(by: amount, in: period, timestamp: timestamp)
	}

	/// Returns this progress with the previous event history preserved when the case matches.
	///
	/// Use this when editing configuration such as target value, step, or unit without changing the user's recorded progress.
	func updated(preservingEventsFrom previousProgress: GoalProgress) -> GoalProgress {
		switch (self, previousProgress) {
		case (.outcome(let progress), .outcome(let previousProgress)):
			.outcome(progress.replacingEvents(with: previousProgress.events))
		case (.measurable(let progress), .measurable(let previousProgress)):
			.measurable(progress.replacingEvents(with: previousProgress.events))
		default:
			self
		}
	}

	@discardableResult
	private mutating func updateProgress(
		outcome updateOutcome: (inout OutcomeProgress) -> Bool,
		measurable updateMeasurable: (inout MeasurableProgress) -> Bool,
	) -> Bool {
		switch self {
		case .outcome(var progress):
			let didChange = updateOutcome(&progress)
			self = .outcome(progress)
			return didChange
		case .measurable(var progress):
			let didChange = updateMeasurable(&progress)
			self = .measurable(progress)
			return didChange
		}
	}

	@discardableResult
	private mutating func updateMeasurableProgress(
		_ update: (inout MeasurableProgress) -> Bool,
	) -> Bool {
		guard case .measurable(var progress) = self else {
			return false
		}
		let didChange = update(&progress)
		self = .measurable(progress)
		return didChange
	}
}

// MARK: - Date+Helpers

nonisolated extension Date {
	func isInsideProgressPeriod(_ period: DateInterval) -> Bool {
		self >= period.start && self < period.end
	}
}
