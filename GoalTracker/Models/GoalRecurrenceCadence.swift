//
//  GoalRecurrenceCadence.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/28/26.
//

import Foundation

/// The cadence used to group progress events for recurring completion.
nonisolated enum GoalRecurrenceCadence: String, Codable, Equatable, Hashable {
	case daily
	case weekly
	case monthly
	case yearly

	static let builtInOptions: [GoalRecurrenceCadence] = [
		.daily,
		.weekly,
		.monthly,
		.yearly
	]

	var displayTitle: LocalizedStringResource {
		switch self {
		case .daily:
			.recurrenceCadenceDaily
		case .weekly:
			.recurrenceCadenceWeekly
		case .monthly:
			.recurrenceCadenceMonthly
		case .yearly:
			.recurrenceCadenceYearly
		}
	}

	var detailTitle: LocalizedStringResource {
		switch self {
		case .daily:
			.recurrenceDetailDaily
		case .weekly:
			.recurrenceDetailWeekly
		case .monthly:
			.recurrenceDetailMonthly
		case .yearly:
			.recurrenceDetailYearly
		}
	}

	var rowTitle: LocalizedStringResource {
		switch self {
		case .daily:
			.recurrenceRowDaily
		case .weekly:
			.recurrenceRowWeekly
		case .monthly:
			.recurrenceRowMonthly
		case .yearly:
			.recurrenceRowYearly
		}
	}

	func streakValueTitle(for count: Int) -> LocalizedStringResource {
		switch self {
		case .daily:
			.recurrenceStreakDaily(count)
		case .weekly:
			.recurrenceStreakWeekly(count)
		case .monthly:
			.recurrenceStreakMonthly(count)
		case .yearly:
			.recurrenceStreakYearly(count)
		}
	}

	func period(
		containing date: Date,
		calendar: Calendar = .current,
	) -> DateInterval? {
		switch self {
		case .daily:
			calendar.dateInterval(of: .day, for: date)
		case .weekly:
			calendar.dateInterval(of: .weekOfYear, for: date)
		case .monthly:
			calendar.dateInterval(of: .month, for: date)
		case .yearly:
			calendar.dateInterval(of: .year, for: date)
		}
	}

	func period(
		before period: DateInterval,
		calendar: Calendar = .current,
	) -> DateInterval? {
		guard
			let dateInPreviousPeriod = calendar.date(
				byAdding: calendarComponent,
				value: -1,
				to: period.start,
			)
		else {
			return nil
		}
		return self.period(containing: dateInPreviousPeriod, calendar: calendar)
	}

	var reminderTargetDescription: LocalizedStringResource {
		switch self {
		case .daily:
			.recurrenceReminderTargetDaily
		case .weekly:
			.recurrenceReminderTargetWeekly
		case .monthly:
			.recurrenceReminderTargetMonthly
		case .yearly:
			.recurrenceReminderTargetYearly
		}
	}

	func reminderDateComponents(calendar: Calendar = .current) -> DateComponents {
		var components = DateComponents()
		components.calendar = calendar
		components.hour = GoalReminder.defaultSettingHour
		components.minute = 0
		components.second = 0

		switch self {
		case .daily:
			break
		case .weekly:
			components.weekday = calendar.firstWeekday
		case .monthly:
			components.day = 1
		case .yearly:
			components.month = 1
			components.day = 1
		}

		return components
	}

	private var calendarComponent: Calendar.Component {
		switch self {
		case .daily:
			.day
		case .weekly:
			.weekOfYear
		case .monthly:
			.month
		case .yearly:
			.year
		}
	}

}
