//
//  GoalFormDataTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/13/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalFormDataTests {
	@Test
	func `Form data preserves reminders from goals`() {
		let reminder = GoalReminder()
		let goal = Goal(
			name: "Test Goal",
			details: nil,
			reminder: reminder,
			createdAt: Date(timeIntervalSinceReferenceDate: 0),
			progress: .outcome(OutcomeProgress()),
		)

		let data = GoalFormData(goal: goal)

		#expect(data.reminder == reminder)
	}

	@Test
	func `Empty form data has no reminder`() {
		#expect(GoalFormData.empty.reminder == nil)
	}

	@Test
	func `Form data maps goal tags to existing selections`() {
		let tag = Tag(name: "Health")
		let goal = Goal(
			name: "Test Goal",
			details: nil,
			createdAt: Date(timeIntervalSinceReferenceDate: 0),
			progress: .outcome(OutcomeProgress()),
		)
		goal.tags = [tag]

		let data = GoalFormData(goal: goal)

		#expect(data.tags.map(\.name) == ["Health"])
		#expect(data.tags.map(\.normalizedName) == ["health"])
	}
}
