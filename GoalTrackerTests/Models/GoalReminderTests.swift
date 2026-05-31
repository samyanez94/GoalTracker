//
//  GoalReminderTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/21/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor struct GoalReminderTests {
	@Test func `New goals default to no reminder`() {
		let goal = makeGoal()

		#expect(goal.reminder == nil)
	}

	@Test func `Goals can be initialized with reminders`() {
		let reminder = GoalReminder()
		let goal = makeGoal(reminder: reminder)

		#expect(goal.reminder == reminder)
	}

	@Test func `Date only reminders calculate from nine AM local time`() throws {
		let calendar = Calendar(identifier: .gregorian)
		let dueDate = try #require(
			calendar.date(from: DateComponents(year: 2026, month: 5, day: 21, ))
		)

		#expect(
			GoalReminder().fireDate(on: dueDate, calendar: calendar)
				== calendar.date(from: DateComponents(year: 2026, month: 5, day: 21, hour: 9), )
		)
	}

	@Test func `Form data preserves reminders from goals`() {
		let reminder = GoalReminder()
		let goal = makeGoal(reminder: reminder)

		let data = GoalFormData(goal: goal)

		#expect(data.reminder == reminder)
	}

	@Test func `Empty form data has no reminder`() { #expect(GoalFormData.empty.reminder == nil) }

	private func makeGoal(reminder: GoalReminder? = nil, ) -> Goal {
		Goal(
			name: "Test Goal",
			details: nil,
			reminder: reminder,
			createdAt: Date(timeIntervalSinceReferenceDate: 0),
			progress: .outcomePending,
		)
	}
}
