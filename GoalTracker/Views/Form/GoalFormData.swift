//
//  GoalFormData.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import Foundation

struct GoalFormData {
	var name: String
	var details: String
	var targetDate: Date?
	var reminder: GoalReminder?
	var progress: GoalProgress
	var recurrence: GoalRecurrence?
	var tags: [Tag]

	static let empty = GoalFormData(
		name: "",
		details: "",
		targetDate: nil,
		reminder: nil,
		progress: .outcome(OutcomeProgress()),
		recurrence: nil,
		tags: [],
	)

	init(goal: Goal) {
		name = goal.name
		details = goal.details ?? ""
		targetDate = goal.targetDate
		reminder = goal.reminder
		progress = goal.progress
		recurrence = goal.recurrence
		tags = goal.tags
	}

	init(
		name: String,
		details: String,
		targetDate: Date? = nil,
		reminder: GoalReminder? = nil,
		progress: GoalProgress,
		recurrence: GoalRecurrence? = nil,
		tags: [Tag] = [],
	) {
		self.name = name
		self.details = details
		self.targetDate = targetDate
		self.reminder = reminder
		self.progress = progress
		self.recurrence = recurrence
		self.tags = tags
	}

	var normalizedDetails: String? {
		let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
		return trimmedDetails.isEmpty ? nil : trimmedDetails
	}
}
