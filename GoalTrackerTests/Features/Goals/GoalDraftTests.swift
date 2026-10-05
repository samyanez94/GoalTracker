//
//  GoalDraftTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/13/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalDraftTests {
	@Test
	func `Goal draft preserves reminders from goals`() {
		let reminder = GoalReminder()
		let goal = Goal(
			name: "Test Goal",
			details: nil,
			reminder: reminder,
			createdAt: Date(timeIntervalSinceReferenceDate: 0),
			progress: .outcome(OutcomeProgress()),
		)

		let data = GoalDraft(goal: goal)

		#expect(data.reminder == reminder)
	}

	@Test
	func `Empty goal draft has no reminder`() {
		#expect(GoalDraft.empty.reminder == nil)
	}

	@Test
	func `Goal draft maps goal tags to draft values`() {
		let tag = Tag(name: "Health")
		let goal = Goal(
			name: "Test Goal",
			details: nil,
			createdAt: Date(timeIntervalSinceReferenceDate: 0),
			progress: .outcome(OutcomeProgress()),
		)
		goal.tags = [tag]

		let data = GoalDraft(goal: goal)

		#expect(data.tags.map(\.name) == ["Health"])
		#expect(data.tags.map(\.normalizedName) == ["health"])
	}
}
