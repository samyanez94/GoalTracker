//
//  GoalService.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation
import SwiftData

/// Coordinates goal write actions using SwiftData's model context.
///
/// `GoalService` does not own or cache goal state. SwiftUI views read goals with `@Query`, then pass the current model values here when an action needs to create, update, delete, or save a goal.
@MainActor
struct GoalService {
	private let modelContext: ModelContext

	private let reminderUpdates: any GoalReminderUpdating

	private let saveContext: () throws -> Void

	private let rollbackContext: () -> Void

	private let now: () -> Date

	/// Initializes a `GoalService`.
	init(
		modelContext: ModelContext,
		reminderUpdates: any GoalReminderUpdating,
		saveContext: (() throws -> Void)? = nil,
		rollbackContext: (() -> Void)? = nil,
		now: @escaping () -> Date = Date.init,
	) {
		self.modelContext = modelContext
		self.reminderUpdates = reminderUpdates
		self.saveContext =
			saveContext ?? {
				try modelContext.save()
			}
		self.rollbackContext =
			rollbackContext ?? {
				modelContext.rollback()
			}
		self.now = now
	}

	/// Inserts a new goal into the model context and saves the change.
	func addGoal(
		_ goal: Goal,
	) throws {
		modelContext.insert(goal)
		try saveChanges()
		reminderUpdates.goalDidChange(goal, reason: .detailsSaved)
	}

	/// Inserts a new goal into the model context using a goal draft.
	func addGoal(
		with draft: GoalDraft,
	) throws {
		let tags = try resolveTags(for: draft.tags)
		let goal = Goal(
			name: draft.name,
			details: draft.normalizedDetails,
			targetDate: draft.targetDate,
			reminder: draft.reminder,
			createdAt: now(),
			progress: draft.progress,
			recurrence: draft.recurrence,
		)
		goal.tags = tags
		try addGoal(goal)
	}

	/// Replaces a goal's editable values with a draft and saves the change.
	///
	/// Start with `GoalDraft(goal:)` to retain values that are not being edited.
	/// Existing progress events are preserved when editing progress settings. Draft
	/// tags are resolved to saved tags, and removed tags are deleted when unused.
	/// A save failure restores the goal's previous values; reminder work starts only
	/// after a successful save.
	func updateGoal(
		_ goal: Goal,
		with draft: GoalDraft,
	) throws {
		let tags = try resolveTags(for: draft.tags)
		let snapshot = GoalSnapshot(goal: goal)
		let previousTags = goal.tags ?? []
		try saveChanges(
			performing: {
				goal.name = draft.name
				goal.details = draft.normalizedDetails
				goal.targetDate = draft.targetDate
				goal.reminder = draft.reminder
				goal.progress = draft.progress.updated(preservingEventsFrom: goal.progress)
				goal.recurrence = draft.recurrence
				let removedTags = tagsRemoved(from: previousTags, afterSelecting: tags)
				goal.tags = tags
				deleteUnusedTags(from: removedTags, ignoringGoalsWithIds: [goal.id])
			},
			restoreOnFailure: {
				snapshot.restore(goal)
			},
		)
		reminderUpdates.goalDidChange(goal, reason: .detailsSaved)
	}

	/// Disables a reminder, cancelling notifications only after the preference is saved.
	func disableReminder(_ goal: Goal) throws {
		let previousReminder = goal.reminder
		try saveChanges(
			performing: { goal.reminder = nil },
			restoreOnFailure: { goal.reminder = previousReminder },
		)
		reminderUpdates.goalDidChange(goal, reason: .reminderDisabled)
	}

	/// Toggles a goal between completed and incomplete states, then saves the change.
	///
	/// - Returns: `true` when the goal's progress changed.
	@discardableResult
	func toggleCompletion(
		_ goal: Goal,
	) throws -> Bool {
		try updateProgress(goal) { goal in
			goal.toggleCompletion(timestamp: now())
		}
	}

	/// Marks a goal as complete and saves the change.
	///
	/// - Returns: `true` when the goal's progress changed.
	@discardableResult
	func completeGoal(
		_ goal: Goal,
	) throws -> Bool {
		try updateProgress(goal) { goal in
			goal.complete(timestamp: now())
		}
	}

	/// Advances a measurable goal by its configured step and saves the change.
	///
	/// - Returns: `true` when the goal's progress changed.
	@discardableResult
	func incrementProgress(
		_ goal: Goal,
	) throws -> Bool {
		try updateProgress(goal) { goal in
			goal.incrementProgress(timestamp: now())
		}
	}

	/// Reduces a measurable goal by its configured step and saves the change.
	///
	/// - Returns: `true` when the goal's progress changed.
	@discardableResult
	func decrementProgress(
		_ goal: Goal,
	) throws -> Bool {
		try updateProgress(goal) { goal in
			goal.decrementProgress(timestamp: now())
		}
	}

	/// Applies a custom signed amount to a measurable goal's progress and saves the change.
	///
	/// - Returns: `true` when the goal's progress changed.
	@discardableResult
	func updateProgress(
		_ goal: Goal,
		by amount: Double,
	) throws -> Bool {
		try updateProgress(goal) { goal in
			goal.updateProgress(by: amount, timestamp: now())
		}
	}

	/// Deletes one measurable progress event by ID and saves the change.
	///
	/// - Returns: `true` when the event was removed, or `false` when the goal is not measurable or deleting the event would leave invalid progress history.
	@discardableResult
	func deleteProgressEvent(
		id: GoalProgressEvent.ID,
		from goal: Goal,
	) throws -> Bool {
		try updateProgress(goal) { goal in
			guard case .measurable(let progress) = goal.progress,
				let updatedProgress = progress.deletingEvent(id: id)
			else {
				return false
			}
			goal.progress = .measurable(updatedProgress)
			return true
		}
	}

	/// Deletes multiple measurable progress events by ID and saves the change.
	///
	/// - Returns: `true` when at least one event was removed, or `false` when the goal is not measurable, none of the IDs match, or deleting the events would leave invalid progress history.
	@discardableResult
	func deleteProgressEvents(
		ids: Set<GoalProgressEvent.ID>,
		from goal: Goal,
	) throws -> Bool {
		try updateProgress(goal) { goal in
			guard case .measurable(let progress) = goal.progress,
				let updatedProgress = progress.deletingEvents(ids: ids)
			else {
				return false
			}
			goal.progress = .measurable(updatedProgress)
			return true
		}
	}

	/// Deletes a single goal and removes any of its tags that are no longer used.
	func deleteGoal(_ goal: Goal) throws {
		try deleteGoals([goal])
	}

	/// Deletes multiple goals and removes any tags that are no longer used.
	func deleteGoals(_ goals: [Goal]) throws {
		let deletedGoalIds = Set(goals.map(\.id))
		let candidateTags = goals.flatMap { $0.tags ?? [] }
		for goal in goals {
			modelContext.delete(goal)
		}
		try saveChanges {
			deleteUnusedTags(
				from: candidateTags,
				ignoringGoalsWithIds: deletedGoalIds,
			)
		}
		reminderUpdates.goalsWereDeleted(deletedGoalIds)
	}

	private func saveChanges(
		performing changes: () throws -> Void = {},
		restoreOnFailure: () -> Void = {},
	) throws {
		do {
			try changes()
			try saveContext()
		} catch {
			rollbackContext()
			restoreOnFailure()
			throw SaveError.failed(error)
		}
	}

	@discardableResult
	private func updateProgress(
		_ goal: Goal,
		_ mutate: (Goal) -> Bool,
	) throws -> Bool {
		let snapshot = GoalSnapshot(goal: goal)
		guard mutate(goal) else {
			return false
		}
		try saveChanges(restoreOnFailure: {
			snapshot.restore(goal)
		})
		reminderUpdates.goalDidChange(goal, reason: .progressSaved)
		return true
	}

	private func deleteUnusedTags(
		from candidateTags: [Tag],
		ignoringGoalsWithIds ignoredGoalIds: Set<UUID> = [],
	) {
		var checkedTagIds: Set<UUID> = []
		for tag in candidateTags {
			guard checkedTagIds.insert(tag.id).inserted else {
				continue
			}
			guard (tag.goals ?? []).allSatisfy({ goal in ignoredGoalIds.contains(goal.id) }) else {
				continue
			}
			modelContext.delete(tag)
		}
	}

	private func tagsRemoved(
		from previousTags: [Tag],
		afterSelecting selectedTags: [Tag],
	) -> [Tag] {
		let selectedTagIds = Set(selectedTags.map(\.id))
		return previousTags.filter { tag in
			!selectedTagIds.contains(tag.id)
		}
	}

	private func resolveTags(for tagDrafts: [GoalTagDraft]) throws -> [Tag] {
		let existingTags = try fetchTags()
		var resolvedTagNames: Set<String> = []
		return tagDrafts.compactMap { tagDraft in
			guard !tagDraft.normalizedName.isEmpty,
				resolvedTagNames.insert(tagDraft.normalizedName).inserted
			else {
				return nil
			}
			if let existingTag = existingTags.first(where: { tag in
				tag.normalizedName == tagDraft.normalizedName
			}) {
				return existingTag
			}
			return newTag(from: tagDraft)
		}
	}

	private func newTag(from tagDraft: GoalTagDraft) -> Tag {
		let tag = Tag(name: tagDraft.name)
		modelContext.insert(tag)
		return tag
	}

	private func fetchTags() throws -> [Tag] {
		try modelContext.fetch(
			FetchDescriptor<Tag>(sortBy: [SortDescriptor<Tag>(\.normalizedName)])
		)
	}

	/// Captures the editable state of a goal before a write operation mutates it.
	///
	/// `GoalSnapshot` lets `GoalService` restore in-memory model values after a SwiftData save failure so the UI and model context return to the last successfully saved state.
	private struct GoalSnapshot {
		let name: String
		let details: String?
		let targetDate: Date?
		let reminder: GoalReminder?
		let progress: GoalProgress
		let recurrence: GoalRecurrence?
		let tags: [Tag]

		init(goal: Goal) {
			name = goal.name
			details = goal.details
			targetDate = goal.targetDate
			reminder = goal.reminder
			progress = goal.progress
			recurrence = goal.recurrence
			tags = goal.tags ?? []
		}

		func restore(_ goal: Goal) {
			goal.name = name
			goal.details = details
			goal.targetDate = targetDate
			goal.reminder = reminder
			goal.progress = progress
			goal.recurrence = recurrence
			goal.tags = tags
		}
	}

	/// Failures that occur while persisting goal changes.
	enum SaveError: LocalizedError {
		/// A save operation failed with the associated underlying error.
		case failed(Error)

		/// A user-facing description suitable for alerts and error messages.
		var errorDescription: String? {
			"Your changes could not be saved."
		}
	}
}
