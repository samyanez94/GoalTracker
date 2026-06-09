//
//  GoalFormScheduleState.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/3/26.
//

import Foundation

/// Keeps track of date, recurrence, and reminder draft state for the goal form.
struct GoalFormScheduleState {
	var targetDate: Date?
	var draftTargetDate: Date {
		didSet {
			guard hasTargetDate else {
				return
			}
			targetDate = draftTargetDate
		}
	}
	var reminder: GoalReminder?

	var recurrence: GoalRecurrence? {
		didSet {
			clearTargetDateIfNeededForRecurrence()
		}
	}

	init(
		targetDate: Date?,
		reminder: GoalReminder?,
		recurrence: GoalRecurrence?,
		defaultTargetDate: Date,
	) {
		self.targetDate = recurrence == nil ? targetDate : nil
		draftTargetDate = targetDate ?? defaultTargetDate
		self.reminder = reminder
		self.recurrence = recurrence
	}

	var allowsTargetDate: Bool {
		recurrence == nil
	}

	var hasTargetDate: Bool {
		get {
			allowsTargetDate && targetDate != nil
		}
		set {
			setTargetDateEnabled(newValue)
		}
	}

	var formTargetDate: Date? {
		allowsTargetDate ? targetDate : nil
	}

	var formReminder: GoalReminder? {
		recurrence != nil || hasTargetDate ? reminder : nil
	}

	var snapshot: Snapshot {
		Snapshot(
			targetDate: formTargetDate,
			reminder: formReminder,
			recurrence: recurrence,
		)
	}

	mutating func setTargetDateEnabled(_ isEnabled: Bool) {
		if isEnabled {
			targetDate = draftTargetDate
		} else {
			targetDate = nil
			if recurrence == nil {
				reminder = nil
			}
		}
	}

	private mutating func clearTargetDateIfNeededForRecurrence() {
		guard recurrence != nil else {
			return
		}
		targetDate = nil
	}

	struct Snapshot: Equatable {
		var targetDate: Date?
		var reminder: GoalReminder?
		var recurrence: GoalRecurrence?
	}
}
