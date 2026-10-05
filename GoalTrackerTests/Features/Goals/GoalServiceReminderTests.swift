//
//  GoalServiceReminderTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 10/5/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import SwiftData
import Testing

@testable import GoalTracker

@MainActor
struct GoalServiceReminderTests {
	@Test
	func `Reminder updates follow successful saves and skip unchanged progress`() throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let reminders = GoalReminderUpdatingSpy()
		reminders.onUpdate = { #expect(!container.mainContext.hasChanges) }
		let service = GoalService(modelContext: container.mainContext, reminderUpdates: reminders)
		let goal = Goal(name: "Read", progress: .outcome(OutcomeProgress()))

		try service.addGoal(goal)
		try service.completeGoal(goal)
		#expect(try !service.completeGoal(goal))
		try service.disableReminder(goal)
		try service.deleteGoal(goal)

		#expect(reminders.changedGoalIDs == [goal.id, goal.id, goal.id])
		#expect(reminders.reasons == [.detailsSaved, .progressSaved, .reminderDisabled])
		#expect(reminders.deletedGoalIDs == [goal.id])
	}

	@Test
	func `Failed saves never reach the reminder dependency`() throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = Goal(name: "Read", progress: .outcome(OutcomeProgress()))
		container.mainContext.insert(goal)
		try container.mainContext.save()
		let reminders = GoalReminderUpdatingSpy()
		let service = GoalService(
			modelContext: container.mainContext,
			reminderUpdates: reminders,
			saveContext: { throw Failure.save }
		)

		#expect(throws: GoalService.SaveError.self) { try service.completeGoal(goal) }
		#expect(throws: GoalService.SaveError.self) { try service.disableReminder(goal) }
		#expect(throws: GoalService.SaveError.self) { try service.deleteGoal(goal) }
		#expect(throws: GoalService.SaveError.self) {
			try service.addGoal(Goal(name: "Walk", progress: .outcome(OutcomeProgress())))
		}
		#expect(reminders.changedGoalIDs.isEmpty)
		#expect(reminders.deletedGoalIDs.isEmpty)
	}

	private enum Failure: Error {
		case save
	}
}
