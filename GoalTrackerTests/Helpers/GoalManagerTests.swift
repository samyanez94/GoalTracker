//
//  GoalManagerTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation
import SwiftData
import Testing

@testable import GoalTracker

// MARK: - GoalManagerTests

@MainActor
struct GoalManagerTests {
	@Test
	func `Incrementing measurable progress appends timestamped event`() async throws {
		let container = try makeContainer()
		let timestamp = Date(timeIntervalSinceReferenceDate: 123)
		let goal = makeGoal(
			progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
		)
		insert(goal, into: container)
		let manager = makeManager(in: container, now: { timestamp })

		let didChange = try manager.incrementProgress(goal)

		#expect(didChange)
		#expect(goal.progress.currentValue == 6)
		#expect(goal.progress.events.map(\.delta) == [4, 2])
		#expect(goal.progress.events.last?.timestamp == timestamp)
	}

	@Test
	func `Completing outcome goal appends timestamped event`() async throws {
		let container = try makeContainer()
		let timestamp = Date(timeIntervalSinceReferenceDate: 123)
		let goal = makeGoal(progress: .outcome(OutcomeProgress()))
		insert(goal, into: container)
		let manager = makeManager(in: container, now: { timestamp })

		let didChange = try manager.completeGoal(goal)

		#expect(didChange)
		#expect(goal.progress.isCompleted)
		#expect(goal.progress.events.map(\.delta) == [1])
		#expect(goal.progress.events.last?.timestamp == timestamp)
	}

	@Test
	func `Recurring measurable progress updates current cadence period only`() async throws {
		let container = try makeContainer()
		let yesterday = date(year: 2026, month: 5, day: 27, hour: 12)
		let today = date(year: 2026, month: 5, day: 28, hour: 12)
		let goal = makeGoal(
			progress: .measurable(
				MeasurableProgress(
					events: [
						GoalProgressEvent(delta: 10, timestamp: yesterday)
					],
					targetValue: 10,
					step: 5,
				)
			),
			recurrence: GoalRecurrence(cadence: .daily),
		)
		insert(goal, into: container)
		let manager = makeManager(in: container, now: { today })

		let didIncrement = try manager.incrementProgress(goal)
		let didComplete = try manager.completeGoal(goal)

		#expect(didIncrement == true)
		#expect(didComplete == true)
		#expect(goal.progress.events.map(\.delta) == [10, 5, 5])
		#expect(goal.currentProgressValue(at: today) == 10)
		#expect(goal.isCompleted(at: today) == true)
	}

	@Test
	func `Custom progress update appends signed amount`() async throws {
		let container = try makeContainer()
		let timestamp = Date(timeIntervalSinceReferenceDate: 123)
		let goal = makeGoal(
			progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
		)
		insert(goal, into: container)
		let manager = makeManager(in: container, now: { timestamp })

		let didChange = try manager.updateProgress(goal, by: 3.5)

		#expect(didChange)
		#expect(goal.progress.currentValue == 7.5)
		#expect(goal.progress.events.map(\.delta) == [4, 3.5])
		#expect(goal.progress.events.last?.timestamp == timestamp)
	}

	@Test
	func `Recurring custom progress update applies to current cadence period only`() async throws {
		let container = try makeContainer()
		let yesterday = date(year: 2026, month: 5, day: 27, hour: 12)
		let today = date(year: 2026, month: 5, day: 28, hour: 12)
		let goal = makeGoal(
			progress: .measurable(
				MeasurableProgress(
					events: [
						GoalProgressEvent(delta: 10, timestamp: yesterday),
						GoalProgressEvent(delta: 4, timestamp: today)
					],
					targetValue: 10,
					step: 5,
				)
			),
			recurrence: GoalRecurrence(cadence: .daily),
		)
		insert(goal, into: container)
		let manager = makeManager(in: container, now: { today })

		let didChange = try manager.updateProgress(goal, by: 3)

		#expect(didChange)
		#expect(goal.progress.events.map(\.delta) == [10, 4, 3])
		#expect(goal.currentProgressValue(at: yesterday) == 10)
		#expect(goal.currentProgressValue(at: today) == 7)
	}

	@Test
	func `Updating recurrence preserves progress history`() async throws {
		let container = try makeContainer()
		let completionDate = date(year: 2026, month: 5, day: 27, hour: 12)
		let currentDate = date(year: 2026, month: 5, day: 28, hour: 12)
		let goal = makeGoal(
			progress: .outcome(
				OutcomeProgress(events: [
					GoalProgressEvent(delta: 1, timestamp: completionDate)
				])
			),
		)
		insert(goal, into: container)
		let manager = makeManager(in: container, now: { currentDate })

		try manager.updateRecurrence(
			goal,
			recurrence: GoalRecurrence(cadence: .daily),
		)

		#expect(goal.recurrence == GoalRecurrence(cadence: .daily))
		#expect(goal.progress.events.map(\.delta) == [1])
		#expect(goal.isCompleted(at: currentDate) == false)
	}

	@Test
	func `Updating goal with form data sets recurrence`() async throws {
		let container = try makeContainer()
		let goal = makeGoal(progress: .outcome(OutcomeProgress()))
		insert(goal, into: container)
		let manager = makeManager(in: container)

		try manager.updateGoal(
			goal,
			with: GoalFormData(
				name: goal.name,
				details: goal.details ?? "",
				progress: goal.progress,
				recurrence: GoalRecurrence(cadence: .monthly),
			),
		)

		#expect(goal.recurrence == GoalRecurrence(cadence: .monthly))
	}

	@Test
	func `Updating goal with form data saves reminder`() async throws {
		let container = try makeContainer()
		let targetDate = Date(timeIntervalSinceReferenceDate: 60 * 60 * 24 * 30)
		let reminder = GoalReminder()
		let goal = makeGoal(
			targetDate: targetDate,
			progress: .outcome(OutcomeProgress()),
		)
		insert(goal, into: container)
		let manager = makeManager(in: container)

		try manager.updateGoal(
			goal,
			with: GoalFormData(
				name: goal.name,
				details: goal.details ?? "",
				targetDate: targetDate,
				reminder: reminder,
				progress: goal.progress,
			),
		)

		#expect(goal.reminder == reminder)
	}

	@Test
	func `Updating goal with form data clears recurrence`() async throws {
		let container = try makeContainer()
		let goal = makeGoal(
			progress: .outcome(OutcomeProgress()),
			recurrence: GoalRecurrence(cadence: .daily),
		)
		insert(goal, into: container)
		let manager = makeManager(in: container)

		try manager.updateGoal(
			goal,
			with: GoalFormData(
				name: goal.name,
				details: goal.details ?? "",
				progress: goal.progress,
				recurrence: nil,
			),
		)

		#expect(goal.recurrence == nil)
	}

	@Test
	func `Direct goal update preserves recurrence`() async throws {
		let container = try makeContainer()
		let recurrence = GoalRecurrence(cadence: .weekly)
		let goal = makeGoal(
			progress: .outcome(OutcomeProgress()),
			recurrence: recurrence,
		)
		insert(goal, into: container)
		let manager = makeManager(in: container)

		try manager.updateGoal(
			goal,
			name: "Updated Goal",
			details: goal.details,
			targetDate: goal.targetDate,
			progress: goal.progress,
		)

		#expect(goal.recurrence == recurrence)
	}

	@Test
	func `Editing measurable form progress preserves existing events`() async throws {
		let container = try makeContainer()
		let originalTimestamp = Date(timeIntervalSinceReferenceDate: 12)
		let goal = makeGoal(
			progress: .measurable(
				currentValue: 4,
				targetValue: 10,
				step: 2,
				timestamp: originalTimestamp,
			),
		)
		insert(goal, into: container)
		let manager = makeManager(
			in: container,
			now: { Date(timeIntervalSinceReferenceDate: 123) },
		)

		try manager.updateGoal(
			goal,
			name: goal.name,
			details: goal.details,
			targetDate: goal.targetDate,
			progress: .measurable(currentValue: .zero, targetValue: 12, step: 3),
		)

		let progress = try #require(goal.progress.measurableProgress)
		#expect(progress.targetValue == 12)
		#expect(progress.step == 3)
		#expect(progress.currentValue == 4)
		#expect(progress.events.count == 1)
		#expect(progress.events.first?.delta == 4)
		#expect(progress.events.first?.timestamp == originalTimestamp)
	}

	@Test
	func `Editing measurable target and step preserves existing events`() async throws {
		let container = try makeContainer()
		let originalTimestamp = Date(timeIntervalSinceReferenceDate: 12)
		let goal = makeGoal(
			progress: .measurable(
				currentValue: 4,
				targetValue: 10,
				step: 2,
				timestamp: originalTimestamp,
			),
		)
		insert(goal, into: container)
		let manager = makeManager(
			in: container,
			now: { Date(timeIntervalSinceReferenceDate: 123) },
		)

		try manager.updateGoal(
			goal,
			name: goal.name,
			details: goal.details,
			targetDate: goal.targetDate,
			progress: .measurable(currentValue: 4, targetValue: 12, step: 3),
		)

		let progress = try #require(goal.progress.measurableProgress)
		#expect(progress.targetValue == 12)
		#expect(progress.step == 3)
		#expect(progress.currentValue == 4)
		#expect(progress.events.count == 1)
		#expect(progress.events.first?.delta == 4)
		#expect(progress.events.first?.timestamp == originalTimestamp)
	}

	@Test
	func `Editing recurring goal reminder preserves current period progress`() async throws {
		let container = try makeContainer()
		let yesterday = date(year: 2026, month: 5, day: 27, hour: 12)
		let today = date(year: 2026, month: 5, day: 28, hour: 12)
		let reminder = GoalReminder()
		let goal = makeGoal(
			progress: .measurable(
				MeasurableProgress(
					events: [
						GoalProgressEvent(delta: 10, timestamp: yesterday),
						GoalProgressEvent(delta: 5, timestamp: today)
					],
					targetValue: 10,
					step: 5,
				)
			),
			recurrence: GoalRecurrence(cadence: .daily),
		)
		insert(goal, into: container)
		let manager = makeManager(in: container, now: { today })

		try manager.updateGoal(
			goal,
			name: goal.name,
			details: goal.details,
			targetDate: goal.targetDate,
			reminder: reminder,
			progress: .measurable(
				currentValue: .zero,
				targetValue: try #require(goal.progress.measurableProgress?.targetValue),
				step: try #require(goal.progress.measurableProgress?.step),
			),
		)

		#expect(goal.reminder == reminder)
		#expect(goal.progress.events.map(\.delta) == [10, 5])
		#expect(goal.currentProgressValue(at: today) == 5)
	}

	@Test
	func `Editing goal updates reminder`() async throws {
		let container = try makeContainer()
		let scheduler = FakeGoalReminderScheduler()
		let goal = makeGoal(
			targetDate: Date(timeIntervalSinceReferenceDate: 60 * 60 * 24 * 30),
			progress: .outcome(OutcomeProgress()),
		)
		let reminder = GoalReminder()
		insert(goal, into: container)
		let manager = makeManager(in: container, notificationScheduler: scheduler)

		try manager.updateGoal(
			goal,
			name: goal.name,
			details: goal.details,
			targetDate: goal.targetDate,
			reminder: reminder,
			progress: goal.progress,
		)

		#expect(goal.reminder == reminder)
		await waitForReminderSync()
		#expect(scheduler.syncedGoalIds == [goal.id])
		#expect(scheduler.syncRequestsAuthorizationFlags == [true])
	}

	@Test
	func `Editing goal updates selected tags`() async throws {
		let container = try makeContainer()
		let goal = makeGoal(progress: .outcome(OutcomeProgress()))
		let healthTag = Tag(name: "Health")
		let runningTag = Tag(name: "Running")
		insert(goal, into: container)
		let manager = makeManager(in: container)

		try manager.updateGoal(
			goal,
			name: goal.name,
			details: goal.details,
			targetDate: goal.targetDate,
			progress: goal.progress,
			tags: [healthTag, runningTag],
		)

		#expect(Set(goal.tags.map(\.name)) == ["Health", "Running"])
	}

	@Test
	func `Editing goal deletes tags that are no longer used`() async throws {
		let container = try makeContainer()
		let oldTag = Tag(name: "Old")
		let newTag = Tag(name: "New")
		let goal = makeGoal(progress: .outcome(OutcomeProgress()))
		goal.tags = [oldTag]
		insert(goal, into: container)
		container.mainContext.insert(newTag)
		try container.mainContext.save()
		let manager = makeManager(in: container)

		try manager.updateGoal(
			goal,
			name: goal.name,
			details: goal.details,
			targetDate: goal.targetDate,
			progress: goal.progress,
			tags: [newTag],
		)

		#expect(Set(try fetchTags(in: container).map(\.name)) == ["New"])
	}

	@Test
	func `Deleting a goal removes it from the model context`() async throws {
		let container = try makeContainer()
		let goal = makeGoal(
			progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
		)
		insert(goal, into: container)
		let manager = makeManager(in: container)

		try manager.deleteGoal(goal)

		#expect(try fetchGoals(in: container).isEmpty)
	}

	@Test
	func `Deleting a goal deletes tags that are no longer used`() async throws {
		let container = try makeContainer()
		let tag = Tag(name: "Solo")
		let goal = makeGoal(progress: .outcome(OutcomeProgress()))
		goal.tags = [tag]
		insert(goal, into: container)
		let manager = makeManager(in: container)

		try manager.deleteGoal(goal)

		#expect(try fetchGoals(in: container).isEmpty)
		#expect(try fetchTags(in: container).isEmpty)
	}

	@Test
	func `Deleting a goal keeps tags used by another goal`() async throws {
		let container = try makeContainer()
		let tag = Tag(name: "Shared")
		let deletedGoal = makeGoal(name: "Deleted Goal", progress: .outcome(OutcomeProgress()))
		let retainedGoal = makeGoal(name: "Retained Goal", progress: .outcome(OutcomeProgress()))
		deletedGoal.tags = [tag]
		retainedGoal.tags = [tag]
		insert(deletedGoal, into: container)
		insert(retainedGoal, into: container)
		let manager = makeManager(in: container)

		try manager.deleteGoal(deletedGoal)

		#expect(try fetchGoals(in: container).map(\.id) == [retainedGoal.id])
		#expect(try fetchTags(in: container).map(\.name) == ["Shared"])
	}

	@Test
	func `Deleting a tag removes it from goals`() throws {
		let container = try makeContainer()
		let tag = Tag(name: "Health")
		let goal = makeGoal(progress: .outcome(OutcomeProgress()))
		goal.tags = [tag]
		insert(goal, into: container)
		let manager = makeManager(in: container)

		try manager.deleteTag(tag)

		let fetchedGoal = try #require(try fetchGoals(in: container).first)
		#expect(try fetchTags(in: container).isEmpty)
		#expect(fetchedGoal.tags.isEmpty)
	}

	@Test
	func `Deleting unused tags keeps protected form selections`() throws {
		let container = try makeContainer()
		let protectedTag = Tag(name: "Selected")
		let unusedTag = Tag(name: "Unused")
		container.mainContext.insert(protectedTag)
		container.mainContext.insert(unusedTag)
		try container.mainContext.save()
		let manager = makeManager(in: container)

		try manager.deleteUnusedTags(excluding: [protectedTag])

		#expect(try fetchTags(in: container).map(\.name) == ["Selected"])
	}

	@Test
	func `Deleting multiple goals removes them from the model context`() async throws {
		let container = try makeContainer()
		let firstGoal = makeGoal(
			name: "First Goal",
			progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
		)
		let secondGoal = makeGoal(
			name: "Second Goal",
			progress: .outcome(OutcomeProgress()),
		)
		let retainedGoal = makeGoal(
			name: "Retained Goal",
			progress: .outcome(OutcomeProgress.completed(timestamp: Date())),
		)
		insert(firstGoal, into: container)
		insert(secondGoal, into: container)
		insert(retainedGoal, into: container)
		let manager = makeManager(in: container)

		try manager.deleteGoals([firstGoal, secondGoal])

		let remainingGoalIDs = try Set(fetchGoals(in: container).map(\.id))
		#expect(remainingGoalIDs == [retainedGoal.id])
	}

	@Test
	func `Bulk delete save failure rolls back deletions and throws`() async throws {
		let container = try makeContainer()
		let firstGoal = makeGoal(
			name: "First Goal",
			progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
		)
		let secondGoal = makeGoal(
			name: "Second Goal",
			progress: .outcome(OutcomeProgress()),
		)
		insert(firstGoal, into: container)
		insert(secondGoal, into: container)
		let manager = GoalManager(
			modelContext: container.mainContext,
			saveContext: {
				throw TestSaveError.failed
			},
		)

		#expect(throws: GoalManager.SaveError.self) {
			try manager.deleteGoals([firstGoal, secondGoal])
		}

		let remainingGoalIDs = try Set(fetchGoals(in: container).map(\.id))
		#expect(remainingGoalIDs == [firstGoal.id, secondGoal.id])
	}

	@Test
	func `Update save failure rolls back goal changes and tag cleanup`() async throws {
		let container = try makeContainer()
		let oldTag = Tag(name: "Old")
		let newTag = Tag(name: "New")
		let goal = makeGoal(
			name: "Original Goal",
			progress: .outcome(OutcomeProgress()),
		)
		goal.tags = [oldTag]
		insert(goal, into: container)
		container.mainContext.insert(newTag)
		try container.mainContext.save()
		let manager = GoalManager(
			modelContext: container.mainContext,
			saveContext: {
				throw TestSaveError.failed
			},
		)

		#expect(throws: GoalManager.SaveError.self) {
			try manager.updateGoal(
				goal,
				name: "Updated Goal",
				details: goal.details,
				targetDate: goal.targetDate,
				reminder: GoalReminder(),
				progress: goal.progress,
				tags: [newTag],
			)
		}

		#expect(goal.name == "Original Goal")
		#expect(goal.reminder == nil)
		#expect(goal.tags.map(\.name) == ["Old"])
		#expect(Set(try fetchTags(in: container).map(\.name)) == ["Old", "New"])
	}

	@Test
	func `Save failure rolls back progress changes and throws`() async throws {
		let container = try makeContainer()
		let goal = makeGoal(
			progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
		)
		insert(goal, into: container)
		let manager = GoalManager(
			modelContext: container.mainContext,
			saveContext: {
				throw TestSaveError.failed
			},
		)

		#expect(throws: GoalManager.SaveError.self) {
			try manager.incrementProgress(goal)
		}
		#expect(goal.progress.currentValue == 4)
	}

	@Test
	func `Adding a goal with a target date schedules notification reminder`() async throws {
		let container = try makeContainer()
		let scheduler = FakeGoalReminderScheduler()
		let goal = makeGoal(
			targetDate: Date(timeIntervalSinceReferenceDate: 60 * 60 * 24 * 30),
			reminder: GoalReminder(),
			progress: .outcome(OutcomeProgress()),
		)
		let manager = makeManager(in: container, notificationScheduler: scheduler)

		try manager.addGoal(goal)

		await waitForReminderSync()
		#expect(scheduler.syncedGoalIds == [goal.id])
		#expect(scheduler.syncRequestsAuthorizationFlags == [true])
		#expect(scheduler.canceledGoalIds.isEmpty)
	}

	@Test
	func `Adding a goal with form data saves reminder`() async throws {
		let container = try makeContainer()
		let targetDate = Date(timeIntervalSinceReferenceDate: 60 * 60 * 24 * 30)
		let reminder = GoalReminder()
		let manager = makeManager(in: container)

		try manager.addGoal(
			with: GoalFormData(
				name: "Read",
				details: "",
				targetDate: targetDate,
				reminder: reminder,
				progress: .outcome(OutcomeProgress()),
			),
		)

		let goal = try #require(
			fetchGoals(in: container).first { goal in
				goal.name == "Read"
			}
		)
		#expect(goal.reminder == reminder)
		#expect(goal.targetDate == targetDate)
	}

	@Test
	func `Editing a goal without reminder eligibility delegates reminder sync`() async throws {
		let container = try makeContainer()
		let scheduler = FakeGoalReminderScheduler()
		let goal = makeGoal(
			targetDate: Date(timeIntervalSinceReferenceDate: 60 * 60 * 24 * 30),
			reminder: GoalReminder(),
			progress: .outcome(OutcomeProgress()),
		)
		insert(goal, into: container)
		let manager = makeManager(in: container, notificationScheduler: scheduler)

		try manager.updateGoal(
			goal,
			name: goal.name,
			details: goal.details,
			targetDate: nil,
			reminder: nil,
			progress: goal.progress,
		)

		await waitForReminderSync()
		#expect(scheduler.syncedGoalIds == [goal.id])
		#expect(scheduler.syncRequestsAuthorizationFlags == [true])
		#expect(scheduler.canceledGoalIds.isEmpty)
	}

	@Test
	func `Completing a goal delegates reminder sync`() async throws {
		let container = try makeContainer()
		let scheduler = FakeGoalReminderScheduler()
		let goal = makeGoal(
			targetDate: Date(timeIntervalSinceReferenceDate: 60 * 60 * 24 * 30),
			reminder: GoalReminder(),
			progress: .outcome(OutcomeProgress()),
		)
		insert(goal, into: container)
		let manager = makeManager(in: container, notificationScheduler: scheduler)

		_ = try manager.completeGoal(goal)

		await waitForReminderSync()
		#expect(scheduler.syncedGoalIds == [goal.id])
		#expect(scheduler.syncRequestsAuthorizationFlags == [false])
		#expect(scheduler.canceledGoalIds.isEmpty)
	}

	@Test
	func `Restoring a completed goal delegates reminder sync`() async throws {
		let container = try makeContainer()
		let scheduler = FakeGoalReminderScheduler()
		let goal = makeGoal(
			targetDate: Date(timeIntervalSinceReferenceDate: 60 * 60 * 24 * 30),
			reminder: GoalReminder(),
			progress: .outcome(OutcomeProgress.completed(timestamp: Date())),
		)
		insert(goal, into: container)
		let manager = makeManager(in: container, notificationScheduler: scheduler)

		_ = try manager.toggleCompletion(goal)

		await waitForReminderSync()
		#expect(scheduler.syncedGoalIds == [goal.id])
		#expect(scheduler.syncRequestsAuthorizationFlags == [false])
	}

	@Test
	func `Deleting goals cancels notification reminders`() async throws {
		let container = try makeContainer()
		let scheduler = FakeGoalReminderScheduler()
		let firstGoal = makeGoal(name: "First Goal", progress: .outcome(OutcomeProgress()))
		let secondGoal = makeGoal(name: "Second Goal", progress: .outcome(OutcomeProgress()))
		insert(firstGoal, into: container)
		insert(secondGoal, into: container)
		let manager = makeManager(in: container, notificationScheduler: scheduler)

		try manager.deleteGoals([firstGoal, secondGoal])

		#expect(Set(scheduler.canceledGoalIds) == [firstGoal.id, secondGoal.id])
	}

	private func makeContainer() throws -> ModelContainer {
		try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
	}

	private func makeManager(
		in container: ModelContainer,
		notificationScheduler: FakeGoalReminderScheduler = FakeGoalReminderScheduler(),
		now: @escaping () -> Date = Date.init,
	) -> GoalManager {
		GoalManager(
			modelContext: container.mainContext,
			notificationScheduler: notificationScheduler,
			now: now,
		)
	}

	private func insert(
		_ goal: Goal,
		into container: ModelContainer,
	) {
		container.mainContext.insert(goal)
		try? container.mainContext.save()
	}

	private func fetchGoals(in container: ModelContainer) throws -> [Goal] {
		try container.mainContext.fetch(FetchDescriptor<Goal>())
	}

	private func fetchTags(in container: ModelContainer) throws -> [GoalTrackerSchemaV1.Tag] {
		try container.mainContext.fetch(
			FetchDescriptor<GoalTrackerSchemaV1.Tag>(
				sortBy: [SortDescriptor<GoalTrackerSchemaV1.Tag>(\.normalizedName)],
			),
		)
	}

	private func waitForReminderSync() async {
		await Task.yield()
		await Task.yield()
	}

	private func makeGoal(
		name: String = "Test Goal",
		targetDate: Date? = nil,
		reminder: GoalReminder? = nil,
		progress: GoalProgress,
		recurrence: GoalRecurrence? = nil,
	) -> Goal {
		Goal(
			name: name,
			details: nil,
			targetDate: targetDate,
			reminder: reminder,
			createdAt: Date(timeIntervalSinceReferenceDate: 0),
			progress: progress,
			recurrence: recurrence,
		)
	}

	private func date(
		year: Int,
		month: Int,
		day: Int,
		hour: Int = 0,
	) -> Date {
		let calendar = Calendar.current
		let components = DateComponents(
			calendar: calendar,
			timeZone: calendar.timeZone,
			year: year,
			month: month,
			day: day,
			hour: hour,
		)
		guard let date = components.date else {
			preconditionFailure("Invalid test date.")
		}
		return date
	}

	private enum TestSaveError: Error {
		case failed
	}
}

// MARK: - FakeGoalReminderScheduler

@MainActor
private final class FakeGoalReminderScheduler: GoalReminderScheduling {
	var syncResult = true

	var syncedGoalIds: [UUID] = []

	var syncRequestsAuthorizationFlags: [Bool] = []

	var canceledGoalIds: [UUID] = []

	func syncReminder(
		for state: GoalReminderSyncState,
		requestsAuthorization: Bool,
	) async throws -> Bool {
		syncedGoalIds.append(state.goalId)
		syncRequestsAuthorizationFlags.append(requestsAuthorization)
		return syncResult
	}

	func cancelReminders(for goalIds: [UUID]) {
		canceledGoalIds.append(contentsOf: goalIds)
	}
}
