//
//  GoalReminderUpdatingSpy.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 10/5/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import Foundation

@testable import GoalTracker

@MainActor
final class GoalReminderUpdatingSpy: GoalReminderUpdating {
	var changedGoalIDs: [UUID] = []
	var reasons: [GoalReminderChange] = []
	var deletedGoalIDs: Set<UUID> = []
	var onUpdate: () -> Void = {}

	func goalDidChange(_ goal: Goal, reason: GoalReminderChange) {
		onUpdate()
		changedGoalIDs.append(goal.id)
		reasons.append(reason)
	}

	func goalsWereDeleted(_ goalIDs: Set<UUID>) {
		onUpdate()
		deletedGoalIDs.formUnion(goalIDs)
	}
}
