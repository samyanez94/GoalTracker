//
//  GoalTargetDateFormatter.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/5/26.
//

import Foundation

enum GoalTargetDateFormatter {
	static func string(
		from date: Date,
		locale: Locale = .current,
		calendar: Calendar = .current,
	) -> String {
		date.formatted(
			Date.RelativeFormatStyle(
				allowedFields: [.day, .week, .month, .year],
				presentation: .named,
				unitsStyle: .wide,
				locale: locale,
				calendar: calendar,
				capitalizationContext: .beginningOfSentence,
			)
		)
	}
}
