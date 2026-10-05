//
//  GoalProgressEventFormatter.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/3/26.
//

import Foundation

// MARK: - GoalProgressEventFormatter

enum GoalProgressEventFormatter {
	static func title(
		for event: GoalProgressEvent,
		unit: GoalProgressUnit?,
	) -> String {
		let amount = formattedAmount(abs(event.delta), unit: unit)
		if event.delta >= 0 {
			return String(localized: .progressEventFormatIncreasedBy(amount))
		}
		return String(localized: .progressEventFormatDecreasedBy(amount))
	}

	static func subtitle(for event: GoalProgressEvent) -> String {
		event.timestamp.formatted(date: .abbreviated, time: .shortened)
	}

	private static func formattedAmount(
		_ amount: Double,
		unit: GoalProgressUnit?,
	) -> String {
		let formattedNumber = formattedNumber(amount)
		if let prefix = unit?.prefix {
			return "\(prefix)\(formattedNumber)"
		}
		if let suffix = unit?.suffix {
			return "\(formattedNumber) \(suffix)"
		}
		if let unit {
			return "\(formattedNumber) \(unit.abbreviatedTitle)"
		}
		return formattedNumber
	}

	private static func formattedNumber(_ value: Double) -> String {
		if value.rounded() == value {
			return Int(value).formatted()
		}
		return value.formatted()
	}
}
