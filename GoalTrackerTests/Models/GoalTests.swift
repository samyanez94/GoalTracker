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
		let goal = makeGoal(progress: .outcome(OutcomeProgress()))

		#expect(goal.status() == .pending)
	}

	@Test
	func `Goal status is in progress when progress is above zero and incomplete`() {
		let goal = makeGoal(progress: .measurable(currentValue: 2, targetValue: 5))

		#expect(goal.status() == .inProgress)
	}

	@Test
	func `Goal status is completed when progress reaches target`() {
		let goal = makeGoal(progress: .outcome(OutcomeProgress.completed(timestamp: Date())))

		#expect(goal.status() == .completed)
	}

	@Test
	func `Recurring goal status is pending when only a previous period is completed`() {
		let goal = makeGoal(
			progress: .outcome(
				OutcomeProgress(events: [
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 27),
					)
				])
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
			progress: .measurable(
				MeasurableProgress(
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
				)
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

	// MARK: - Target Date

	@Test
	func `Goal is past target date when incomplete target date is before current day`() {
		let goal = makeGoal(
			targetDate: ModelTestSupport.date(year: 2026, month: 5, day: 27),
		)

		#expect(
			goal.isPastTargetDate(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28),
				calendar: ModelTestSupport.calendar,
			)
		)
	}

	@Test
	func `Goal is not past target date when target date is current day`() {
		let goal = makeGoal(
			targetDate: ModelTestSupport.date(year: 2026, month: 5, day: 28),
		)

		#expect(
			!goal.isPastTargetDate(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28, hour: 12),
				calendar: ModelTestSupport.calendar,
			)
		)
	}

	@Test
	func `Completed goal is not past target date`() {
		let goal = makeGoal(
			targetDate: ModelTestSupport.date(year: 2026, month: 5, day: 27),
			progress: .outcome(
				OutcomeProgress.completed(
					timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 28),
				)
			),
		)

		#expect(
			!goal.isPastTargetDate(
				at: ModelTestSupport.date(year: 2026, month: 5, day: 28),
				calendar: ModelTestSupport.calendar,
			)
		)
	}

	// MARK: - Streaks

	@Test
	func `Non recurring goal has no current streak`() {
		let goal = Goal(
			name: "Read",
			details: nil,
			createdAt: ModelTestSupport.date(year: 2026, month: 5, day: 28),
			progress: .outcome(OutcomeProgress.completed(timestamp: Date())),
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
			progress: .outcome(
				OutcomeProgress(events: [
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 27),
					),
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 26),
					)
				])
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
			progress: .outcome(
				OutcomeProgress(events: [
					GoalProgressEvent(
						delta: 1,
						timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 26),
					)
				])
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
			progress: .measurable(
				MeasurableProgress(
					events: [
						GoalProgressEvent(
							delta: 10,
							timestamp: ModelTestSupport.date(year: 2026, month: 5, day: 29),
						)
					],
					targetValue: 10,
				)
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
			progress: .outcome(
				OutcomeProgress(events: [
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
				])
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
			progress: .outcome(
				OutcomeProgress(events: [
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
				])
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
			progress: .measurable(
				MeasurableProgress(
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
				)
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
			progress: .outcome(OutcomeProgress()),
			recurrence: GoalRecurrence(cadence: .monthly),
		)
		container.mainContext.insert(goal)
		try container.mainContext.save()

		let fetchedGoals = try container.mainContext.fetch(FetchDescriptor<Goal>())
		let fetchedGoal = try #require(fetchedGoals.first)

		#expect(fetchedGoal.recurrence == GoalRecurrence(cadence: .monthly))
	}

	@Test
	func `Measurable goal progress persists with SwiftData`() throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let timestamp = ModelTestSupport.date(year: 2026, month: 5, day: 28)
		let goal = Goal(
			name: "Run",
			details: nil,
			createdAt: timestamp,
			progress: .measurable(
				currentValue: 4,
				targetValue: 10,
				step: 2,
				unit: .kilometers,
				timestamp: timestamp,
			),
		)
		container.mainContext.insert(goal)
		try container.mainContext.save()

		let fetchedGoals = try container.mainContext.fetch(FetchDescriptor<Goal>())
		let fetchedGoal = try #require(fetchedGoals.first)
		let progress = try #require(fetchedGoal.progress.measurableProgress)

		#expect(progress.currentValue == 4)
		#expect(progress.targetValue == 10)
		#expect(progress.step == 2)
		#expect(progress.unit == .kilometers)
	}

	@Test
	func `Measurable goal progress without unit persists with SwiftData`() throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let timestamp = ModelTestSupport.date(year: 2026, month: 5, day: 28)
		let goal = Goal(
			name: "Run",
			details: nil,
			createdAt: timestamp,
			progress: .measurable(
				currentValue: 4,
				targetValue: 10,
				step: 2,
				unit: nil,
				timestamp: timestamp,
			),
		)
		container.mainContext.insert(goal)
		try container.mainContext.save()

		let fetchedGoals = try container.mainContext.fetch(FetchDescriptor<Goal>())
		let fetchedGoal = try #require(fetchedGoals.first)
		let progress = try #require(fetchedGoal.progress.measurableProgress)

		#expect(progress.currentValue == 4)
		#expect(progress.targetValue == 10)
		#expect(progress.step == 2)
		#expect(progress.unit == nil)
	}

	// MARK: - Helpers

	private func makeGoal(
		targetDate: Date? = nil,
		progress: GoalProgress = .outcome(OutcomeProgress()),
		recurrence: GoalRecurrence? = nil,
	) -> Goal {
		Goal(
			name: "Test Goal",
			details: nil,
			targetDate: targetDate,
			createdAt: Date(timeIntervalSinceReferenceDate: 0),
			progress: progress,
			recurrence: recurrence,
		)
	}
}
