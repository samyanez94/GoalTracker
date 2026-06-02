//
//  MeasurableProgress.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation

/// Tracks progress for a goal that advances toward a numeric target.
nonisolated struct MeasurableProgress: Codable, Equatable {
	/// Timestamped progress changes for this goal.
	private(set) var events: [GoalProgressEvent]
	/// The value at which the goal is considered complete.
	let targetValue: Double
	/// The amount used when stepping progress up or down.
	let step: Double

	/// The optional unit used when displaying progress values.
	var unit: GoalProgressUnit? { unitStorage.resolvedUnit() }

	private let unitStorage: GoalProgressUnitStorage

	/// The user's current progress toward the target value.
	var currentValue: Double {
		boundedValue(from: eventValue)
	}

	/// Whether the current value has reached or exceeded the target value.
	var isCompleted: Bool {
		currentValue >= targetValue
	}

	/// Whether there is progress available to subtract.
	var canDecrement: Bool {
		currentValue > 0
	}

	/// Whether there is still room to add more progress.
	var canIncrement: Bool {
		currentValue < upperBound
	}

	/// The progress amount represented from 0 to 1.
	var fractionCompleted: Double {
		currentValue / targetValue
	}

	init(
		events: [GoalProgressEvent],
		targetValue: Double,
		step: Double = 1,
		unit: GoalProgressUnit? = nil,
	) {
		precondition(
			Self.isValid(
				events: events,
				targetValue: targetValue,
				step: step,
			),
			"Measurable progress values must be finite, non-negative, and have a positive target and step.",
		)
		self.events = events
		self.targetValue = targetValue
		self.step = step
		unitStorage = GoalProgressUnitStorage(unit)
	}

	init(
		currentValue: Double,
		targetValue: Double,
		step: Double = 1,
		unit: GoalProgressUnit? = nil,
		timestamp: Date = Date(),
	) {
		precondition(
			Self.isValid(
				currentValue: currentValue,
				targetValue: targetValue,
				step: step,
			),
			"Measurable progress values must be finite, non-negative, and have a positive target and step.",
		)
		self.init(
			events: Self.events(for: currentValue, timestamp: timestamp),
			targetValue: targetValue,
			step: step,
			unit: unit,
		)
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let events = try container.decode([GoalProgressEvent].self, forKey: .events)
		let targetValue = try container.decode(Double.self, forKey: .targetValue)
		let step = try container.decodeIfPresent(Double.self, forKey: .step) ?? 1
		let unitStorage =
			try container.decodeIfPresent(GoalProgressUnitStorage.self, forKey: .unitStorage)
			?? GoalProgressUnitStorage()
		guard
			Self.isValid(
				events: events,
				targetValue: targetValue,
				step: step,
			)
		else {
			throw DecodingError.dataCorrupted(
				DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription: "Measurable progress values must be finite, non-negative, and have a positive target and step.",
				),
			)
		}
		self.events = events
		self.targetValue = targetValue
		self.step = step
		self.unitStorage = unitStorage
	}

	static func isValid(
		events: [GoalProgressEvent],
		targetValue: Double,
		step: Double,
	) -> Bool {
		let currentValue = events.reduce(0) { $0 + $1.delta }
		return events.allSatisfy { $0.delta.isFinite }
			&& currentValue.isFinite
			&& targetValue.isFinite
			&& step.isFinite
			&& currentValue >= 0
			&& targetValue > 0
			&& step > 0
	}

	static func isValid(
		currentValue: Double,
		targetValue: Double,
		step: Double,
	) -> Bool {
		currentValue.isFinite
			&& targetValue.isFinite
			&& step.isFinite
			&& currentValue >= 0
			&& targetValue > 0
			&& step > 0
			&& currentValue <= targetValue
	}

	@discardableResult
	mutating func complete(timestamp: Date = Date()) -> Bool {
		setCurrentValue(targetValue, timestamp: timestamp)
	}

	@discardableResult
	mutating func reset(timestamp: Date = Date()) -> Bool {
		setCurrentValue(0, timestamp: timestamp)
	}

	@discardableResult
	mutating func toggleCompletion(timestamp: Date = Date()) -> Bool {
		isCompleted ? reset(timestamp: timestamp) : complete(timestamp: timestamp)
	}

	@discardableResult
	mutating func increment(timestamp: Date = Date()) -> Bool {
		setCurrentValue(currentValue + step, timestamp: timestamp)
	}

	@discardableResult
	mutating func decrement(timestamp: Date = Date()) -> Bool {
		setCurrentValue(currentValue - step, timestamp: timestamp)
	}

	@discardableResult
	mutating func update(
		by amount: Double,
		timestamp: Date = Date(),
	) -> Bool {
		guard amount.isFinite else {
			return false
		}
		return setCurrentValue(currentValue + amount, timestamp: timestamp)
	}

	func currentValue(in period: DateInterval) -> Double {
		boundedValue(from: eventValue(in: period))
	}

	func isCompleted(in period: DateInterval) -> Bool {
		currentValue(in: period) >= targetValue
	}

	func canDecrement(in period: DateInterval) -> Bool {
		currentValue(in: period) > 0
	}

	func canIncrement(in period: DateInterval) -> Bool {
		currentValue(in: period) < upperBound
	}

	func fractionCompleted(in period: DateInterval) -> Double {
		currentValue(in: period) / targetValue
	}

	@discardableResult
	mutating func complete(
		in period: DateInterval,
		timestamp: Date = Date(),
	) -> Bool {
		setCurrentValue(targetValue, in: period, timestamp: timestamp)
	}

	@discardableResult
	mutating func reset(
		in period: DateInterval,
		timestamp: Date = Date(),
	) -> Bool {
		setCurrentValue(0, in: period, timestamp: timestamp)
	}

	@discardableResult
	mutating func toggleCompletion(
		in period: DateInterval,
		timestamp: Date = Date(),
	) -> Bool {
		isCompleted(in: period)
			? reset(in: period, timestamp: timestamp)
			: complete(in: period, timestamp: timestamp)
	}

	@discardableResult
	mutating func increment(
		in period: DateInterval,
		timestamp: Date = Date(),
	) -> Bool {
		setCurrentValue(
			currentValue(in: period) + step,
			in: period,
			timestamp: timestamp,
		)
	}

	@discardableResult
	mutating func decrement(
		in period: DateInterval,
		timestamp: Date = Date(),
	) -> Bool {
		setCurrentValue(
			currentValue(in: period) - step,
			in: period,
			timestamp: timestamp,
		)
	}

	@discardableResult
	mutating func update(
		by amount: Double,
		in period: DateInterval,
		timestamp: Date = Date(),
	) -> Bool {
		guard amount.isFinite else {
			return false
		}
		return setCurrentValue(
			currentValue(in: period) + amount,
			in: period,
			timestamp: timestamp,
		)
	}

	func replacingEvents(with events: [GoalProgressEvent]) -> MeasurableProgress {
		MeasurableProgress(
			events: events,
			targetValue: targetValue,
			step: step,
			unit: unit,
		)
	}

	private enum CodingKeys: String, CodingKey {
		case events
		case targetValue
		case step
		case unitStorage
	}

	private var upperBound: Double {
		max(0, targetValue)
	}

	private var eventValue: Double {
		events.reduce(0) { $0 + $1.delta }
	}

	private func eventValue(in period: DateInterval) -> Double {
		events.reduce(0) { value, event in
			guard event.timestamp.isInsideProgressPeriod(period) else {
				return value
			}
			return value + event.delta
		}
	}

	private func boundedValue(from value: Double) -> Double {
		min(max(0, value), upperBound)
	}

	private static func events(
		for currentValue: Double,
		timestamp: Date,
	) -> [GoalProgressEvent] {
		guard currentValue > 0 else {
			return []
		}
		return [
			GoalProgressEvent(delta: currentValue, timestamp: timestamp)
		]
	}

	@discardableResult
	private mutating func setCurrentValue(
		_ value: Double,
		timestamp: Date,
	) -> Bool {
		let updatedValue = min(max(0, value), upperBound)
		let delta = updatedValue - eventValue
		guard delta != 0 else {
			return false
		}
		events.append(GoalProgressEvent(delta: delta, timestamp: timestamp))
		return true
	}

	@discardableResult
	private mutating func setCurrentValue(
		_ value: Double,
		in period: DateInterval,
		timestamp: Date,
	) -> Bool {
		let updatedValue = min(max(0, value), upperBound)
		let delta = updatedValue - eventValue(in: period)
		guard delta != 0 else {
			return false
		}
		events.append(GoalProgressEvent(delta: delta, timestamp: timestamp))
		return true
	}
}
