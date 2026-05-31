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

	static let builtInOptions: [GoalRecurrenceCadence] = [.daily, .weekly, .monthly, .yearly]

	var displayTitle: String {
		switch self {
		case .daily: "Daily"
		case .weekly: "Weekly"
		case .monthly: "Monthly"
		case .yearly: "Yearly"
		}
	}

	var detailTitle: String {
		switch self {
		case .daily: "Repeats every day"
		case .weekly: "Repeats every week"
		case .monthly: "Repeats every month"
		case .yearly: "Repeats every year"
		}
	}

	var rowTitle: String {
		switch self {
		case .daily: "Every day"
		case .weekly: "Every week"
		case .monthly: "Every month"
		case .yearly: "Every year"
		}
	}

	func streakValueTitle(for count: Int) -> String { "\(count) \(streakUnitTitle(for: count))" }

	func period(containing date: Date, calendar: Calendar = .current, ) -> DateInterval? {
		switch self {
		case .daily: calendar.dateInterval(of: .day, for: date)
		case .weekly: calendar.dateInterval(of: .weekOfYear, for: date)
		case .monthly: calendar.dateInterval(of: .month, for: date)
		case .yearly: calendar.dateInterval(of: .year, for: date)
		}
	}

	func period(before period: DateInterval, calendar: Calendar = .current, ) -> DateInterval? {
		guard
			let dateInPreviousPeriod = calendar.date(
				byAdding: calendarComponent,
				value: -1,
				to: period.start,
			)
		else { return nil }
		return self.period(containing: dateInPreviousPeriod, calendar: calendar)
	}

	var reminderDueDescription: String {
		switch self {
		case .daily: "today"
		case .weekly: "this week"
		case .monthly: "this month"
		case .yearly: "this year"
		}
	}

	func reminderDateComponents(calendar: Calendar = .current) -> DateComponents {
		var components = DateComponents()
		components.calendar = calendar
		components.hour = GoalReminder.defaultSettingHour
		components.minute = 0
		components.second = 0

		switch self {
		case .daily: break
		case .weekly: components.weekday = calendar.firstWeekday
		case .monthly: components.day = 1
		case .yearly:
			components.month = 1
			components.day = 1
		}

		return components
	}

	private var calendarComponent: Calendar.Component {
		switch self {
		case .daily: .day
		case .weekly: .weekOfYear
		case .monthly: .month
		case .yearly: .year
		}
	}

	private func streakUnitTitle(for count: Int) -> String {
		switch self {
		case .daily: count == 1 ? "day" : "days"
		case .weekly: count == 1 ? "week" : "weeks"
		case .monthly: count == 1 ? "month" : "months"
		case .yearly: count == 1 ? "year" : "years"
		}
	}
}
