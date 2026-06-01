//
//  GoalTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation
import SwiftData
import Testing

@testable import GoalTracker

@MainActor
struct GoalTests {
	// MARK: - Status

	@Test
	func `Goal status is pending when progress is zero`() {
		let goal = makeGoal(progress: .outcomePending)

		#expect(goal.status() == .pending)
	}

	@Test
	func `Goal status is in progress when progress is above zero and incomplete`() {
		let goal = makeGoal(progress: .measurable(currentValue: 2, targetValue: 5))

		#expect(goal.status() == .inProgress)
	}

	@Test
	func `Goal status is completed when progress reaches target`() {
		let goal = makeGoal(progress: .outcomeCompleted)

		#expect(goal.status() == .completed)
	}

	@Test
	func `Recurring goal status is pending when only a previous period is completed`() {
		let goal = makeGoal(
			progress: GoalProgress(
				kind: .outcome,
				events: [
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 27),
					)
				],
				targetValue: 1,
				step: 1,
			),
			recurrence: GoalRecurrence(cadence: .daily),
		)

		#expect(
			goal.status(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28),
				calendar: ModelTestSupport.calendar,
			) == .pending
		)
		#expect(
			goal.isCompleted(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28),
				calendar: ModelTestSupport.calendar,
			) == false
		)
	}

	@Test
	func `Recurring measurable goal status uses current period progress`() {
		let goal = makeGoal(
			progress: GoalProgress(
				kind: .measurable,
				events: [
					GoalProgressEvent(
						delta: 10,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 27),
					),
					GoalProgressEvent(
						delta: 4,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 28, hour: 10),
					)
				],
				targetValue: 10,
				step: 2,
			),
			recurrence: GoalRecurrence(cadence: .daily),
		)

		#expect(
			goal.currentProgressValue(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28, hour: 12),
				calendar: ModelTestSupport.calendar,
			) == 4
		)
		#expect(
			goal.status(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28, hour: 12),
				calendar: ModelTestSupport.calendar,
			) == .inProgress
		)
	}

	// MARK: - Streaks

	@Test
	func `Non recurring goal has no current streak`() {
		let goal = Goal(
			name: "Read",
			details: nil,
			createdAt: ModelTestSupport.date(year: 2026, month: 5, day: 28),
			progress: .outcomeCompleted,
		)

		#expect(
			goal.currentStreak(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28),
				calendar: ModelTestSupport.calendar,
			) == nil
		)
	}

	@Test
	func `Incomplete current period preserves previous completed streak`() {
		let goal = Goal(
			name: "Read",
			details: nil,
			createdAt: ModelTestSupport.date(year: 2026, month: 5, day: 28),
			progress: GoalProgress(
				kind: .outcome,
				events: [
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 27),
					),
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 26),
					)
				],
				targetValue: 1,
			),
			recurrence: GoalRecurrence(cadence: .daily),
		)

		#expect(
			goal.currentStreak(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28),
				calendar: ModelTestSupport.calendar,
			) == 2
		)
	}

	@Test
	func `Current streak resets after a missed elapsed period`() {
		let goal = Goal(
			name: "Read",
			details: nil,
			createdAt: ModelTestSupport.date(year: 2026, month: 5, day: 26),
			progress: GoalProgress(
				kind: .outcome,
				events: [
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 26),
					)
				],
				targetValue: 1,
			),
			recurrence: GoalRecurrence(cadence: .daily),
		)

		#expect(
			goal.currentStreak(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28),
				calendar: ModelTestSupport.calendar,
			) == 0
		)
	}

	@Test
	func `Current streak ignores progress outside current period`() {
		let goal = Goal(
			name: "Run",
			details: nil,
			createdAt: ModelTestSupport.date(year: 2026, month: 5, day: 28),
			progress: GoalProgress(
				kind: .measurable,
				events: [
					GoalProgressEvent(
						delta: 10,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 29),
					)
				],
				targetValue: 10,
			),
			recurrence: GoalRecurrence(cadence: .daily),
		)

		#expect(
			goal.currentStreak(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28, hour: 12),
				calendar: ModelTestSupport.calendar
			) == 0
		)
	}

	@Test
	func `Daily current streak counts consecutive completed periods`() {
		let goal = Goal(
			name: "Read",
			details: nil,
			createdAt: ModelTestSupport.date(year: 2026, month: 5, day: 28),
			progress: GoalProgress(
				kind: .outcome,
				events: [
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 28),
					),
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 27),
					),
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 26),
					)
				],
				targetValue: 1,
			),
			recurrence: GoalRecurrence(cadence: .daily),
		)

		#expect(
			goal.currentStreak(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28, hour: 12),
				calendar: ModelTestSupport.calendar
			) == 3
		)
	}

	@Test
	func `Current streak stops at the first incomplete period`() {
		let goal = Goal(
			name: "Read",
			details: nil,
			createdAt: ModelTestSupport.date(year: 2026, month: 5, day: 25),
			progress: GoalProgress(
				kind: .outcome,
				events: [
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 28),
					),
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 27),
					),
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 25),
					)
				],
				targetValue: 1,
			),
			recurrence: GoalRecurrence(cadence: .daily),
		)

		#expect(
			goal.currentStreak(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28, hour: 12),
				calendar: ModelTestSupport.calendar
			) == 2
		)
	}

	@Test
	func `Measurable current streak uses completed cadence periods`() {
		let goal = Goal(
			name: "Run",
			details: nil,
			createdAt: ModelTestSupport.date(year: 2026, month: 5, day: 1),
			progress: GoalProgress(
				kind: .measurable,
				events: [
					GoalProgressEvent(
						delta: 10,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 28),
					),
					GoalProgressEvent(
						delta: 10,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 21),
					),
					GoalProgressEvent(
						delta: 5,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 14),
					)
				],
				targetValue: 10,
			),
			recurrence: GoalRecurrence(cadence: .weekly),
		)

		#expect(
			goal.currentStreak(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28, hour: 12),
				calendar: ModelTestSupport.calendar
			) == 2
		)
	}

	// MARK: - Persistence

	@Test
	func `Goal recurrence persists with SwiftData`() throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = Goal(
			name: "Read",
			details: nil,
			createdAt: ModelTestSupport.date(year: 2026, month: 5, day: 28),
			progress: .outcomePending,
			recurrence: GoalRecurrence(cadence: .monthly),
		)
		container.mainContext.insert(goal)
		try container.mainContext.save()

		let fetchedGoals = try container.mainContext.fetch(FetchDescriptor<Goal>())
		let fetchedGoal = try #require(fetchedGoals.first)

		#expect(fetchedGoal.recurrence == GoalRecurrence(cadence: .monthly))
	}

	// MARK: - Helpers

	private func makeGoal(
		progress: GoalProgress = .outcomePending,
		recurrence: GoalRecurrence? = nil,
	) -> Goal {
		Goal(
			name: "Test Goal",
			details: nil,
			createdAt: Date(timeIntervalSinceReferenceDate: 0),
			progress: progress,
			recurrence: recurrence,
		)
	}
}
