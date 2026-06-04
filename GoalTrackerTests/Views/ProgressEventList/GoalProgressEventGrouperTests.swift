//
//  GoalProgressEventGrouperTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 6/4/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalProgressEventGrouperTests {
	@Test
	func `Default newest first groups events by relative date bucket`() {
		let sections = GoalProgressEventGrouper.sections(
			for: [
				event(delta: 1, year: 2025, month: 8, day: 1),
				event(delta: 2, year: 2026, month: 6, day: 18),
				event(delta: 3, year: 2026, month: 6, day: 20, hour: 9),
				event(delta: 4, year: 2026, month: 6, day: 5),
				event(delta: 5, year: 2024, month: 12, day: 31),
				event(delta: 6, year: 2026, month: 1, day: 10),
			],
			now: date(year: 2026, month: 6, day: 20, hour: 12),
			calendar: calendar,
		)

		#expect(sections.map(\.title) == ["Today", "This Week", "This Month", "This Year", "2025", "2024"])
		#expect(sections.map { $0.events.map(\.delta) } == [[3], [2], [4], [6], [1], [5]])
	}

	@Test
	func `Oldest first reverses the timeline section order`() {
		let sections = GoalProgressEventGrouper.sections(
			for: [
				event(delta: 1, year: 2025, month: 8, day: 1),
				event(delta: 2, year: 2026, month: 6, day: 18),
				event(delta: 3, year: 2026, month: 6, day: 20, hour: 9),
				event(delta: 4, year: 2026, month: 6, day: 5),
				event(delta: 5, year: 2024, month: 12, day: 31),
				event(delta: 6, year: 2026, month: 1, day: 10),
			],
			sortOrder: .oldestFirst,
			now: date(year: 2026, month: 6, day: 20, hour: 12),
			calendar: calendar,
		)

		#expect(sections.map(\.title) == ["2024", "2025", "This Year", "This Month", "This Week", "Today"])
		#expect(sections.map { $0.events.map(\.delta) } == [[5], [1], [6], [4], [2], [3]])
	}

	@Test
	func `Events stay newest first within each section`() {
		let sections = GoalProgressEventGrouper.sections(
			for: [
				event(delta: 1, year: 2026, month: 6, day: 4, hour: 8),
				event(delta: 2, year: 2026, month: 6, day: 4, hour: 14),
				event(delta: 3, year: 2026, month: 6, day: 4, hour: 10),
			],
			now: date(year: 2026, month: 6, day: 4, hour: 16),
			calendar: calendar,
		)

		let todaySection = sections.first

		#expect(todaySection?.title == "Today")
		#expect(todaySection?.events.map(\.delta) == [2, 3, 1])
	}

	@Test
	func `Oldest first sorts events within each section by oldest timestamp`() {
		let sections = GoalProgressEventGrouper.sections(
			for: [
				event(delta: 1, year: 2026, month: 6, day: 4, hour: 8),
				event(delta: 2, year: 2026, month: 6, day: 4, hour: 14),
				event(delta: 3, year: 2026, month: 6, day: 4, hour: 10),
			],
			sortOrder: .oldestFirst,
			now: date(year: 2026, month: 6, day: 4, hour: 16),
			calendar: calendar,
		)

		let todaySection = sections.first

		#expect(todaySection?.title == "Today")
		#expect(todaySection?.events.map(\.delta) == [1, 3, 2])
	}

	@Test
	func `Grouped events preserve event ids after sorting`() {
		let events = [
			event(delta: 1, year: 2026, month: 6, day: 4, hour: 8),
			event(delta: 2, year: 2026, month: 6, day: 4, hour: 14),
			event(delta: 3, year: 2026, month: 6, day: 4, hour: 10),
		]

		let sections = GoalProgressEventGrouper.sections(
			for: events,
			now: date(year: 2026, month: 6, day: 4, hour: 16),
			calendar: calendar,
		)

		let todaySection = sections.first

		#expect(todaySection?.events.map(\.delta) == [2, 3, 1])
		#expect(todaySection?.events.map(\.id) == [
			events[1].id,
			events[2].id,
			events[0].id,
		])
	}

	private var calendar: Calendar {
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
		calendar.firstWeekday = 2
		return calendar
	}

	private func event(
		delta: Double,
		year: Int,
		month: Int,
		day: Int,
		hour: Int = 12,
	) -> GoalProgressEvent {
		GoalProgressEvent(
			delta: delta,
			timestamp: date(year: year, month: month, day: day, hour: hour),
		)
	}

	private func date(
		year: Int,
		month: Int,
		day: Int,
		hour: Int,
	) -> Date {
		var components = DateComponents()
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
		calendar.firstWeekday = 2
		components.calendar = calendar
		components.timeZone = TimeZone(secondsFromGMT: 0)
		components.year = year
		components.month = month
		components.day = day
		components.hour = hour
		return components.date ?? Date(timeIntervalSinceReferenceDate: 0)
	}
}
