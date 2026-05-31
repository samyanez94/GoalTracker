//
//  GoalStatusTests.swift
//  GoalTrackerTests
//
//  Created by Codex on 5/27/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor struct GoalStatusTests {
	@Test func `Goal status is pending when progress is zero`() {
		let goal = makeGoal(progress: .outcomePending)

		#expect(goal.status == .pending)
		#expect(goal.status.displayString == "Pending")
		#expect(goal.status.iconSystemName == "circle")
	}

	@Test func `Goal status is in progress when progress is above zero and incomplete`() {
		let goal = makeGoal(progress: .measurable(currentValue: 2, targetValue: 5))

		#expect(goal.status == .inProgress)
		#expect(goal.status.displayString == "In Progress")
		#expect(goal.status.iconSystemName == "circle")
	}

	@Test func `Goal status is completed when progress reaches target`() {
		let goal = makeGoal(progress: .outcomeCompleted)

		#expect(goal.status == .completed)
		#expect(goal.status.displayString == "Completed")
		#expect(goal.status.iconSystemName == "checkmark.circle.fill")
	}

	@Test func `Recurring goal status is pending when only a previous period is completed`() {
		let goal = makeGoal(
			progress: GoalProgress(
				kind: .outcome,
				events: [
					GoalProgressEvent(delta: 1, timestamp: date(year: 2026, month: 5, day: 27), )
				],
				targetValue: 1,
				step: 1,
			),
			recurrence: GoalRecurrence(cadence: .daily),
		)

		#expect(
			goal.status(at: date(year: 2026, month: 5, day: 28), calendar: calendar, ) == .pending
		)
		#expect(
			goal.isCompleted(at: date(year: 2026, month: 5, day: 28), calendar: calendar, ) == false
		)
	}

	@Test func `Recurring measurable goal status uses current period progress`() {
		let goal = makeGoal(
			progress: GoalProgress(
				kind: .measurable,
				events: [
					GoalProgressEvent(delta: 10, timestamp: date(year: 2026, month: 5, day: 27), ),
					GoalProgressEvent(
						delta: 4,
						timestamp: date(year: 2026, month: 5, day: 28, hour: 10),
					),
				],
				targetValue: 10,
				step: 2,
			),
			recurrence: GoalRecurrence(cadence: .daily),
		)

		#expect(
			goal.currentProgressValue(
				at: date(year: 2026, month: 5, day: 28, hour: 12),
				calendar: calendar,
			) == 4
		)
		#expect(
			goal.status(at: date(year: 2026, month: 5, day: 28, hour: 12), calendar: calendar, )
				== .inProgress
		)
	}

	private var calendar: Calendar {
		var calendar = Calendar(identifier: .gregorian)
		guard let timeZone = TimeZone(secondsFromGMT: 0) else {
			preconditionFailure("Unable to create GMT test time zone.")
		}
		calendar.timeZone = timeZone
		calendar.firstWeekday = 2
		return calendar
	}

	private func makeGoal(progress: GoalProgress, recurrence: GoalRecurrence? = nil, ) -> Goal {
		Goal(
			name: "Test Goal",
			details: nil,
			createdAt: Date(),
			progress: progress,
			recurrence: recurrence,
		)
	}

	private func date(year: Int, month: Int, day: Int, hour: Int = 0, ) -> Date {
		let components = DateComponents(
			calendar: calendar,
			timeZone: calendar.timeZone,
			year: year,
			month: month,
			day: day,
			hour: hour,
		)
		guard let date = components.date else { preconditionFailure("Invalid test date.") }
		return date
	}
}
