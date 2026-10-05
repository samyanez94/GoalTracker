//
//  GoalProgressEventGrouper.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/4/26.
//

import Foundation

// MARK: - GoalProgressEventGrouper

enum GoalProgressEventGrouper {
	static func sections(
		for events: [GoalProgressEvent],
		sortOrder: GoalProgressEventSortOrder = .newestFirst,
		now: Date = Date(),
		calendar: Calendar = .current,
	) -> [GoalProgressEventSection] {
		let eventsByBucket = Dictionary(grouping: events) { event in
			EventBucket(
				for: event.timestamp,
				now: now,
				calendar: calendar,
			)
		}
		return eventsByBucket.keys
			.sorted { lhs, rhs in
				lhs.isOrdered(before: rhs, sortOrder: sortOrder)
			}
			.map { bucket in
				bucket.section(
					events: sortOrder.sorted(eventsByBucket[bucket] ?? []),
				)
			}
	}

	// MARK: - EventBucket

	private enum EventBucket: Hashable {
		case today
		case thisWeek
		case thisMonth
		case thisYear
		case year(Int)

		init(
			for date: Date,
			now: Date,
			calendar: Calendar,
		) {
			if calendar.isDate(date, inSameDayAs: now) {
				self = .today
			} else if date.isInside(calendar.dateInterval(of: .weekOfYear, for: now)) {
				self = .thisWeek
			} else if date.isInside(calendar.dateInterval(of: .month, for: now)) {
				self = .thisMonth
			} else if date.isInside(calendar.dateInterval(of: .year, for: now)) {
				self = .thisYear
			} else {
				self = .year(calendar.component(.year, from: date))
			}
		}

		var id: String {
			switch self {
			case .today:
				"today"
			case .thisWeek:
				"thisWeek"
			case .thisMonth:
				"thisMonth"
			case .thisYear:
				"thisYear"
			case .year(let year):
				"year.\(year)"
			}
		}

		func section(events: [GoalProgressEvent]) -> GoalProgressEventSection {
			switch self {
			case .today:
				makeSection(title: .progressEventGroupToday, events: events)
			case .thisWeek:
				makeSection(title: .progressEventGroupThisWeek, events: events)
			case .thisMonth:
				makeSection(title: .progressEventGroupThisMonth, events: events)
			case .thisYear:
				makeSection(title: .progressEventGroupThisYear, events: events)
			case .year(let year):
				makeSection(
					title: year.formatted(.number.grouping(.never)),
					events: events,
				)
			}
		}

		private func makeSection(
			title: LocalizedStringResource,
			events: [GoalProgressEvent],
		) -> GoalProgressEventSection {
			GoalProgressEventSection(
				id: id,
				title: title,
				events: events,
			)
		}

		private func makeSection(
			title: String,
			events: [GoalProgressEvent],
		) -> GoalProgressEventSection {
			GoalProgressEventSection(
				id: id,
				title: title,
				events: events,
			)
		}

		func isOrdered(
			before otherBucket: EventBucket,
			sortOrder: GoalProgressEventSortOrder,
		) -> Bool {
			switch sortOrder {
			case .newestFirst:
				isNewestFirstOrdered(before: otherBucket)
			case .oldestFirst:
				otherBucket.isNewestFirstOrdered(before: self)
			}
		}

		private func isNewestFirstOrdered(before otherBucket: EventBucket) -> Bool {
			switch (relativeSortValue, otherBucket.relativeSortValue) {
			case (.some(let value), .some(let otherValue)):
				value < otherValue
			case (.some, .none):
				true
			case (.none, .some):
				false
			case (.none, .none):
				yearValue > otherBucket.yearValue
			}
		}

		private var relativeSortValue: Int? {
			switch self {
			case .today:
				0
			case .thisWeek:
				1
			case .thisMonth:
				2
			case .thisYear:
				3
			case .year:
				nil
			}
		}

		private var yearValue: Int {
			guard case .year(let year) = self else {
				return 0
			}
			return year
		}
	}
}

extension GoalProgressEventSortOrder {
	fileprivate func sorted(_ events: [GoalProgressEvent]) -> [GoalProgressEvent] {
		events.sorted { lhs, rhs in
			switch self {
			case .newestFirst:
				lhs.timestamp > rhs.timestamp
			case .oldestFirst:
				lhs.timestamp < rhs.timestamp
			}
		}
	}
}

// MARK: - Date+Helpers

extension Date {
	fileprivate func isInside(_ interval: DateInterval?) -> Bool {
		guard let interval else {
			return false
		}
		return interval.contains(self)
	}
}
