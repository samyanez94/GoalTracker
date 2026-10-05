//
//  GoalReminderScheduleTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 6/1/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalReminderScheduleTests {
	@Test
	func `One-time reminder creates non-repeating schedule for future fire date`() throws {
		let goalID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
		let targetDate = ModelTestSupport.date(year: 2026, month: 5, day: 21)
		let schedule = try #require(
			reminderSchedule(
				for: makeGoal(
					id: goalID,
					targetDate: targetDate,
					reminder: GoalReminder(),
				),
				currentDate: ModelTestSupport.date(year: 2026, month: 5, day: 20),
			)
		)

		#expect(schedule.goalId == goalID)
		#expect(schedule.goalName == "File taxes")
		#expect(schedule.repeats == false)
		#expect(schedule.triggerDateComponents.year == 2026)
		#expect(schedule.triggerDateComponents.month == 5)
		#expect(schedule.triggerDateComponents.day == 21)
		#expect(schedule.triggerDateComponents.hour == 9)
		#expect(schedule.triggerDateComponents.minute == 0)
		#expect(schedule.triggerDateComponents.second == 0)

		switch schedule.targetDescription {
		case .date(let scheduledTargetDate):
			#expect(scheduledTargetDate == targetDate)
		case .cadence:
			Issue.record("Expected a one-time target date description.")
		}
	}

	@Test
	func `One-time reminder requires a reminder and target date`() {
		let missingReminder = reminderSchedule(
			for: makeGoal(
				targetDate: ModelTestSupport.date(year: 2026, month: 5, day: 21),
			)
		)
		let missingTargetDate = reminderSchedule(
			for: makeGoal(
				reminder: GoalReminder(),
			)
		)

		#expect(missingReminder == nil)
		#expect(missingTargetDate == nil)
	}

	@Test
	func `One-time reminder skips completed goals`() {
		let schedule = reminderSchedule(
			for: makeGoal(
				targetDate: ModelTestSupport.date(year: 2026, month: 5, day: 21),
				reminder: GoalReminder(),
				progress: .outcome(
					OutcomeProgress.completed(
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 20),
					)
				),
			)
		)

		#expect(schedule == nil)
	}

	@Test
	func `One-time reminder skips elapsed fire dates`() {
		let schedule = reminderSchedule(
			for: makeGoal(
				targetDate: ModelTestSupport.date(year: 2026, month: 5, day: 21),
				reminder: GoalReminder(),
			),
			currentDate: ModelTestSupport.date(year: 2026, month: 5, day: 21, hour: 10),
		)

		#expect(schedule == nil)
	}

	@Test(
		arguments: [
			(
				GoalRecurrenceCadence.daily,
				nil as Int?,
				nil as Int?,
				nil as Int?
			),
			(
				.weekly,
				nil as Int?,
				nil as Int?,
				2 as Int?
			),
			(
				.monthly,
				nil as Int?,
				1 as Int?,
				nil as Int?
			),
			(
				.yearly,
				1 as Int?,
				1 as Int?,
				nil as Int?
			)
		]
	)
	func `Recurring reminder creates repeating schedule for cadence`(
		cadence: GoalRecurrenceCadence,
		expectedMonth: Int?,
		expectedDay: Int?,
		expectedWeekday: Int?,
	) throws {
		let schedule = try #require(
			reminderSchedule(
				for: makeGoal(
					reminder: GoalReminder(),
					recurrence: GoalRecurrence(cadence: cadence),
				)
			)
		)

		#expect(schedule.repeats)
		#expect(schedule.triggerDateComponents.year == nil)
		#expect(schedule.triggerDateComponents.month == expectedMonth)
		#expect(schedule.triggerDateComponents.day == expectedDay)
		#expect(schedule.triggerDateComponents.weekday == expectedWeekday)
		#expect(schedule.triggerDateComponents.hour == 9)
		#expect(schedule.triggerDateComponents.minute == 0)
		#expect(schedule.triggerDateComponents.second == 0)

		switch schedule.targetDescription {
		case .date:
			Issue.record("Expected a recurring cadence description.")
		case .cadence(let scheduledCadence):
			#expect(scheduledCadence == cadence)
		}
	}

	@Test
	func `Recurring reminder remains eligible after current period completion`() throws {
		let schedule = try #require(
			reminderSchedule(
				for: makeGoal(
					reminder: GoalReminder(),
					progress: .outcome(
						OutcomeProgress(events: [
							GoalProgressEvent(
								delta: 1,
								timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 21),
							)
						])
					),
					recurrence: GoalRecurrence(cadence: .daily),
				)
			)
		)

		#expect(schedule.repeats)
	}

	private func reminderSchedule(
		for goal: Goal,
		currentDate: Date = ModelTestSupport.date(year: 2026, month: 5, day: 20),
	) -> GoalReminderSchedule? {
		GoalReminderSchedule.reminder(
			state: GoalReminderSyncState(goal: goal),
			calendar: ModelTestSupport.calendar,
			currentDate: currentDate,
		)
	}

	private func makeGoal(
		id: UUID = UUID(),
		targetDate: Date? = nil,
		reminder: GoalReminder? = nil,
		progress: GoalProgress = .outcome(OutcomeProgress()),
		recurrence: GoalRecurrence? = nil,
	) -> Goal {
		Goal(
			id: id,
			name: "File taxes",
			details: nil,
			targetDate: targetDate,
			reminder: reminder,
			createdAt: ModelTestSupport.date(year: 2026, month: 1, day: 1),
			progress: progress,
			recurrence: recurrence,
		)
	}
}
