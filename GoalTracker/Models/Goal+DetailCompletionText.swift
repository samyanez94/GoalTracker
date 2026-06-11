//
//  Goal+DetailCompletionText.swift
//  GoalTracker
//
//  Created by Codex on 6/11/26.
//

import Foundation

extension Goal {
	@MainActor
	func detailCompletionFooterText(
		at date: Date = Date(),
		calendar: Calendar = .current,
		locale: Locale = .current,
	) -> LocalizedStringResource? {
		guard isCompleted(at: date, calendar: calendar) else {
			return nil
		}
		if let recurrence {
			return recurrence.detailCompletionFooterText(
				date: date,
				calendar: calendar,
			)
		}
		return progress.detailCompletionFooterText(
			calendar: calendar,
			locale: locale,
		)
	}
}

private extension GoalProgress {
	nonisolated func detailCompletionFooterText(
		calendar: Calendar,
		locale: Locale,
	) -> LocalizedStringResource? {
		guard let completionDate else {
			return nil
		}
		return .detailCompletedOnDate(
			completionDate.formattedDetailCompletionDate(
				calendar: calendar,
				locale: locale,
			)
		)
	}

	nonisolated var completionDate: Date? {
		switch self {
		case .outcome:
			completionDate(targetValue: 1)
		case .measurable(let progress):
			completionDate(targetValue: progress.targetValue)
		}
	}
}

private extension GoalRecurrence {
	nonisolated func detailCompletionFooterText(
		date: Date,
		calendar: Calendar,
	) -> LocalizedStringResource? {
		guard let period = period(containing: date, calendar: calendar) else {
			return nil
		}
		let completedText = String(
			localized: cadence.completedPeriodText
		)
		let daysUntilReset = calendar.daysUntilReset(from: date, in: period)
		return .detailCompletedResetText(
			completedText: completedText,
			daysUntilReset: daysUntilReset,
		)
	}
}

private extension GoalProgress {
	nonisolated func completionDate(targetValue: Double) -> Date? {
		var currentValue = 0.0
		var completionDate: Date?
		for event in chronologicalEvents {
			let wasCompleted = currentValue.reachesTarget(targetValue)
			currentValue += event.delta
			let isCompleted = currentValue.reachesTarget(targetValue)
			if !wasCompleted && isCompleted {
				completionDate = event.timestamp
			} else if wasCompleted && !isCompleted {
				completionDate = nil
			}
		}

		return currentValue.reachesTarget(targetValue) ? completionDate : nil
	}

	nonisolated var chronologicalEvents: [GoalProgressEvent] {
		events
			.enumerated()
			.sorted { lhs, rhs in
				if lhs.element.timestamp == rhs.element.timestamp {
					return lhs.offset < rhs.offset
				}
				return lhs.element.timestamp < rhs.element.timestamp
			}
			.map(\.element)
	}
}

private extension Calendar {
	nonisolated func daysUntilReset(from date: Date, in period: DateInterval) -> Int {
		max(1, dayCount(from: date, to: period.end))
	}

	nonisolated func dayCount(from startDate: Date, to endDate: Date) -> Int {
		let startOfStartDate = startOfDay(for: startDate)
		let startOfEndDate = startOfDay(for: endDate)
		return dateComponents(
			[.day],
			from: startOfStartDate,
			to: startOfEndDate,
		).day ?? 0
	}
}

private extension Date {
	nonisolated func formattedDetailCompletionDate(
		calendar: Calendar,
		locale: Locale,
	) -> String {
		formatted(
			Date.FormatStyle(
				date: .abbreviated,
				time: .omitted,
				locale: locale,
				calendar: calendar,
				timeZone: calendar.timeZone,
			)
		)
	}
}

private extension Double {
	nonisolated func reachesTarget(_ targetValue: Double) -> Bool {
		min(max(self, 0), targetValue) >= targetValue
	}
}

private extension LocalizedStringResource {
	nonisolated static func detailCompletedResetText(
		completedText: String,
		daysUntilReset: Int,
	) -> LocalizedStringResource {
		if daysUntilReset == 1 {
			return .detailCompletedResetsTomorrow(completedText)
		}
		return .detailCompletedResetsInDays(completedText, daysUntilReset)
	}
}

private extension GoalRecurrenceCadence {
	nonisolated var completedPeriodText: LocalizedStringResource {
		switch self {
		case .daily:
			.detailCompletedToday
		case .weekly:
			.detailCompletedThisWeek
		case .monthly:
			.detailCompletedThisMonth
		case .yearly:
			.detailCompletedThisYear
		}
	}
}
