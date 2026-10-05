//
//  OutcomeProgress.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation

/// Tracks completion for a binary goal using timestamped completion changes.
///
/// Outcome goals are conceptually pending or complete, but they still preserve event history so recurring goals can evaluate completion within each cadence period.
nonisolated struct OutcomeProgress: Codable, Equatable {
	/// Timestamped completion changes for this goal.
	private(set) var events: [GoalProgressEvent]

	/// The user's current binary completion value, represented as 0 or 1.
	var currentValue: Double {
		boundedValue(from: eventValue)
	}

	/// Whether the outcome has been completed.
	var isCompleted: Bool {
		currentValue == 1
	}

	/// The completion amount represented from 0 to 1.
	var fractionCompleted: Double {
		isCompleted ? 1 : 0
	}

	init(events: [GoalProgressEvent] = []) {
		precondition(
			Self.isValid(events: events),
			"Outcome progress events must be finite, binary deltas, and non-negative overall.",
		)
		self.events = events
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let events = try container.decode([GoalProgressEvent].self, forKey: .events)
		guard Self.isValid(events: events) else {
			throw DecodingError.dataCorrupted(
				DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription: "Outcome progress events must be finite, binary deltas, and non-negative overall.",
				),
			)
		}
		self.events = events
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(events, forKey: .events)
	}

	static func completed(timestamp: Date) -> OutcomeProgress {
		OutcomeProgress(events: [
			GoalProgressEvent(delta: 1, timestamp: timestamp)
		])
	}

	static func isValid(events: [GoalProgressEvent]) -> Bool {
		let currentValue = events.reduce(0) { $0 + $1.delta }
		return events.allSatisfy { event in
			event.delta.isFinite && abs(event.delta) == 1
		}
			&& currentValue.isFinite
			&& currentValue >= 0
	}

	func currentValue(in period: DateInterval) -> Double {
		boundedValue(from: eventValue(in: period))
	}

	func isCompleted(in period: DateInterval) -> Bool {
		currentValue(in: period) == 1
	}

	func fractionCompleted(in period: DateInterval) -> Double {
		isCompleted(in: period) ? 1 : 0
	}

	@discardableResult
	mutating func complete(timestamp: Date = Date()) -> Bool {
		setCurrentValue(1, timestamp: timestamp)
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
	mutating func complete(
		in period: DateInterval,
		timestamp: Date = Date(),
	) -> Bool {
		setCurrentValue(1, in: period, timestamp: timestamp)
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

	func replacingEvents(with events: [GoalProgressEvent]) -> OutcomeProgress {
		OutcomeProgress(events: events)
	}

	private enum CodingKeys: String, CodingKey {
		case events
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
		min(max(0, value), 1)
	}

	@discardableResult
	private mutating func setCurrentValue(
		_ value: Double,
		timestamp: Date,
	) -> Bool {
		let updatedValue = min(max(0, value), 1)
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
		let updatedValue = min(max(0, value), 1)
		let delta = updatedValue - eventValue(in: period)
		guard delta != 0 else {
			return false
		}
		events.append(GoalProgressEvent(delta: delta, timestamp: timestamp))
		return true
	}
}
