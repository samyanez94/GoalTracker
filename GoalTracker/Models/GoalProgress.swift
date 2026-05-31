//
//  GoalProgress.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation

/// Stores the current progress summary for a goal.
///
/// `GoalProgress` is the source of truth for where a goal stands right now.
///
nonisolated struct GoalProgress: Codable {
	/// Whether this progress represents a binary outcome or a measurable target.
	private(set) var kind: GoalProgressKind
	/// Timestamped progress changes for this goal.
	private(set) var events: [GoalProgressEvent]
	/// The value at which the goal is considered complete.
	private(set) var targetValue: Double
	/// The amount used when stepping measurable progress up or down.
	private(set) var step: Double
	/// The optional unit used when displaying measurable progress values.
	private(set) var unit: GoalProgressUnit?

	static let outcomePending = GoalProgress(
		kind: .outcome,
		events: [],
		targetValue: 1,
		step: 1,
		unit: nil,
	)

	static let outcomeCompleted = GoalProgress(
		kind: .outcome,
		events: [
			GoalProgressEvent(delta: 1, timestamp: Date(timeIntervalSinceReferenceDate: 0))
		],
		targetValue: 1,
		step: 1,
		unit: nil,
	)

	/// The user's current progress toward the target value.
	var currentValue: Double {
		boundedValue(from: eventValue)
	}

	/// Whether the current value has reached or exceeded the target value.
	var isCompleted: Bool {
		currentValue >= targetValue
	}

	var isMeasurable: Bool {
		kind == .measurable
	}

	var canDecrement: Bool {
		isMeasurable && currentValue > 0
	}

	var canIncrement: Bool {
		isMeasurable && currentValue < upperBound
	}

	/// The progress amount represented from 0 to 1.
	var fractionCompleted: Double {
		guard targetValue > 0 else {
			return isCompleted ? 1 : 0
		}
		return currentValue / targetValue
	}

	init(
		kind: GoalProgressKind,
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
			"Progress values must be finite, non-negative, and have a positive target and step.",
		)
		self.kind = kind
		self.events = events
		self.targetValue = targetValue
		self.step = step
		self.unit = unit
	}

	init(
		currentValue: Double,
		targetValue: Double,
		step: Double = 1,
		unit: GoalProgressUnit? = nil,
		timestamp: Date = Date(),
	) {
		self.init(
			kind: .measurable,
			events: Self.events(for: currentValue, timestamp: timestamp),
			targetValue: targetValue,
			step: step,
			unit: unit,
		)
	}

	static func measurable(
		currentValue: Double,
		targetValue: Double,
		step: Double = 1,
		unit: GoalProgressUnit? = nil,
		timestamp: Date = Date(),
	) -> GoalProgress {
		GoalProgress(
			kind: .measurable,
			events: events(for: currentValue, timestamp: timestamp),
			targetValue: targetValue,
			step: step,
			unit: unit,
		)
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
		guard isMeasurable else {
			return false
		}
		return setCurrentValue(currentValue + step, timestamp: timestamp)
	}

	@discardableResult
	mutating func decrement(timestamp: Date = Date()) -> Bool {
		guard isMeasurable else {
			return false
		}
		return setCurrentValue(currentValue - step, timestamp: timestamp)
	}

	@discardableResult
	mutating func update(
		by amount: Double,
		timestamp: Date = Date(),
	) -> Bool {
		guard isMeasurable, amount.isFinite else {
			return false
		}
		return setCurrentValue(currentValue + amount, timestamp: timestamp)
	}

	@discardableResult
	mutating func replaceCurrentValue(
		_ currentValue: Double,
		timestamp: Date = Date(),
	) -> Bool {
		setCurrentValue(currentValue, timestamp: timestamp)
	}

	func currentValue(in period: DateInterval) -> Double {
		boundedValue(from: eventValue(in: period))
	}

	func isCompleted(in period: DateInterval) -> Bool {
		currentValue(in: period) >= targetValue
	}

	func canDecrement(in period: DateInterval) -> Bool {
		isMeasurable && currentValue(in: period) > 0
	}

	func canIncrement(in period: DateInterval) -> Bool {
		isMeasurable && currentValue(in: period) < upperBound
	}

	func fractionCompleted(in period: DateInterval) -> Double {
		guard targetValue > 0 else {
			return isCompleted(in: period) ? 1 : 0
		}
		return currentValue(in: period) / targetValue
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
		guard isMeasurable else {
			return false
		}
		return setCurrentValue(
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
		guard isMeasurable else {
			return false
		}
		return setCurrentValue(
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
		guard isMeasurable,
			amount.isFinite
		else {
			return false
		}
		return setCurrentValue(
			currentValue(in: period) + amount,
			in: period,
			timestamp: timestamp,
		)
	}

	func updated(
		preservingEventsFrom previousProgress: GoalProgress,
		timestamp: Date = Date(),
	) -> GoalProgress {
		guard kind == previousProgress.kind else {
			return self
		}
		let updatedCurrentValue = currentValue
		var updatedProgress = self
		updatedProgress.events = previousProgress.events
		guard updatedCurrentValue != previousProgress.currentValue else {
			return updatedProgress
		}
		updatedProgress.replaceCurrentValue(updatedCurrentValue, timestamp: timestamp)
		return updatedProgress
	}

	init(from decoder: Decoder) throws {
		let storage = try GoalProgressStorage(from: decoder)
		guard
			Self.isValid(
				events: storage.events,
				targetValue: storage.targetValue,
				step: storage.step,
			)
		else {
			throw DecodingError.dataCorrupted(
				DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription:
						"Progress values must be finite, non-negative, and have a positive target and step.",
				),
			)
		}
		kind = storage.kind
		events = storage.events
		targetValue = storage.targetValue
		step = storage.step
		unit = storage.unit?.resolvedUnit()
	}

	func encode(to encoder: Encoder) throws {
		try GoalProgressStorage(
			kind: kind,
			events: events,
			targetValue: targetValue,
			step: step,
			unit: unit,
		)
		.encode(to: encoder)
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

nonisolated extension Date {
	fileprivate func isInsideProgressPeriod(_ period: DateInterval) -> Bool {
		self >= period.start && self < period.end
	}
}

nonisolated private struct GoalProgressStorage: Codable {
	var kind: GoalProgressKind
	var events: [GoalProgressEvent]
	var targetValue: Double
	var step: Double
	var unit: GoalProgressUnitSnapshot?

	private enum CodingKeys: String, CodingKey {
		case kind
		case events
		case targetValue
		case step
		case unit
	}

	init(
		kind: GoalProgressKind,
		events: [GoalProgressEvent],
		targetValue: Double,
		step: Double,
		unit: GoalProgressUnit?,
	) {
		self.kind = kind
		self.events = events
		self.targetValue = targetValue
		self.step = step
		self.unit = unit.map(GoalProgressUnitSnapshot.init)
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		kind = try container.decode(GoalProgressKind.self, forKey: .kind)
		events = try container.decode([GoalProgressEvent].self, forKey: .events)
		targetValue = try container.decode(Double.self, forKey: .targetValue)
		step = try container.decodeIfPresent(Double.self, forKey: .step) ?? 1
		unit = try container.decodeIfPresent(GoalProgressUnitSnapshot.self, forKey: .unit)
	}
}

nonisolated private struct GoalProgressUnitSnapshot: Codable {
	var id: String?
	var category: GoalProgressUnit.Category?
	var title: String?
	var abbreviatedTitle: String?
	var prefix: String?
	var suffix: String?

	init(_ unit: GoalProgressUnit) {
		id = unit.id
		category = unit.category
		title = unit.title
		abbreviatedTitle = unit.abbreviatedTitle
		prefix = unit.prefix
		suffix = unit.suffix
	}

	func resolvedUnit() -> GoalProgressUnit? {
		guard let id else {
			return nil
		}
		if let preset = GoalProgressUnit.preset(withID: id) {
			return preset
		}
		let fallbackTitle = title ?? abbreviatedTitle ?? id
		return GoalProgressUnit(
			id: id,
			category: category ?? .custom,
			title: fallbackTitle,
			abbreviatedTitle: abbreviatedTitle ?? fallbackTitle,
			prefix: prefix,
			suffix: suffix,
		)
	}
}
