//
//  GoalManager.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation
import SwiftData

/// Coordinates goal write actions using SwiftData's model context.
///
/// `GoalManager` does not own or cache goal state. SwiftUI views read goals with
/// `@Query`, then pass the current model values here when an action needs to
/// create, update, delete, or save a goal.
@MainActor
struct GoalManager {
    private let modelContext: ModelContext

    private let notificationScheduler: any GoalReminderScheduling

    private let saveContext: () throws -> Void

    private let rollbackContext: () -> Void

    private let now: () -> Date

    /// Initializes a `GoalManager`.
    init(
        modelContext: ModelContext,
        notificationScheduler: any GoalReminderScheduling = GoalNotificationScheduler(),
        saveContext: (() throws -> Void)? = nil,
        rollbackContext: (() -> Void)? = nil,
        now: @escaping () -> Date = Date.init,
    ) {
        self.modelContext = modelContext
        self.notificationScheduler = notificationScheduler
        self.saveContext = saveContext ?? {
            try modelContext.save()
        }
        self.rollbackContext = rollbackContext ?? {
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
        syncReminder(for: goal, requestsAuthorization: true)
    }

    /// Updates a goal's editable fields, cleans up unused tags, and saves the change.
    ///
    /// When `tags` is provided, the goal's tag relationship is replaced and any
    /// tags that are no longer attached to a goal are deleted.
    func updateGoal(
        _ goal: Goal,
        name: String,
        details: String?,
        dueDate: Date?,
        earlyReminder: GoalReminder? = nil,
        progress: GoalProgress,
        tags: [Tag]? = nil,
    ) throws {
        let snapshot = GoalSnapshot(goal: goal)
        let previousTags = goal.tags
        try saveChanges(
            performing: {
                goal.name = name
                goal.details = details
                goal.dueDate = dueDate
                goal.earlyReminder = earlyReminder
                goal.progress = progress.updated(
                    preservingEventsFrom: goal.progress,
                    timestamp: now(),
                )
                if let tags {
                    goal.tags = tags
                    try deleteUnusedTags(
                        from: previousTags + tags,
                        excluding: tags,
                    )
                }
            },
            restoreOnFailure: {
                snapshot.restore(goal)
            },
        )
        syncReminder(for: goal, requestsAuthorization: true)
    }

    /// Updates a goal using values collected by the goal form.
    func updateGoal(
        _ goal: Goal,
        with data: GoalFormData,
    ) throws {
        try updateGoal(
            goal,
            name: data.name,
            details: data.normalizedDetails,
            dueDate: data.dueDate,
            earlyReminder: data.earlyReminder,
            progress: data.progress,
            tags: data.tags,
        )
    }

    /// Updates a goal's recurrence without changing its existing progress history.
    func updateRecurrence(
        _ goal: Goal,
        recurrence: GoalRecurrence?,
    ) throws {
        let snapshot = GoalSnapshot(goal: goal)
        try saveChanges(
            performing: {
                goal.recurrence = recurrence
            },
            restoreOnFailure: {
                snapshot.restore(goal)
            },
        )
        syncReminder(for: goal)
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

    /// Deletes a single goal and removes any of its tags that are no longer used.
    func deleteGoal(_ goal: Goal) throws {
        try deleteGoals([goal])
    }

    /// Deletes a tag and saves the change.
    ///
    /// SwiftData updates goal relationships for the deleted tag.
    func deleteTag(_ tag: Tag) throws {
        modelContext.delete(tag)
        try saveChanges()
    }

    /// Deletes multiple goals and removes any tags that are no longer used.
    func deleteGoals(_ goals: [Goal]) throws {
        let deletedGoalIds = Set(goals.map(\.id))
        let candidateTags = goals.flatMap(\.tags)
        for goal in goals {
            modelContext.delete(goal)
        }
        try saveChanges {
            try deleteUnusedTags(
                from: candidateTags,
                ignoringGoalsWithIds: deletedGoalIds,
            )
        }
        notificationScheduler.cancelReminders(for: Array(deletedGoalIds))
    }

    /// Deletes tags that are not attached to any goal.
    ///
    /// Pass `protectedTags` to keep tags that should survive this cleanup, such as
    /// tags currently selected in a goal form that has not been saved yet.
    func deleteUnusedTags(excluding protectedTags: [Tag] = []) throws {
        try saveChanges {
            try deleteUnusedTags(
                from: fetchTags(),
                excluding: protectedTags,
            )
        }
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
        syncReminder(for: goal)
        return true
    }

    private func syncReminder(
        for goal: Goal,
        requestsAuthorization: Bool = false,
    ) {
        let reminderState = GoalReminderSyncState(goal: goal)
        Task { @MainActor in
            try? await notificationScheduler.syncReminder(
                for: reminderState,
                requestsAuthorization: requestsAuthorization,
            )
        }
    }

    private func deleteUnusedTags(
        from candidateTags: [Tag],
        excluding protectedTags: [Tag] = [],
        ignoringGoalsWithIds ignoredGoalIds: Set<UUID> = [],
    ) throws {
        let protectedTagIds = Set(protectedTags.map(\.id))
        let usedTagIds = try usedTagIds(ignoringGoalsWithIds: ignoredGoalIds)
        var checkedTagIds: Set<UUID> = []
        for tag in candidateTags where !protectedTagIds.contains(tag.id) {
            guard !checkedTagIds.contains(tag.id) else {
                continue
            }
            checkedTagIds.insert(tag.id)
            guard !usedTagIds.contains(tag.id) else {
                continue
            }
            modelContext.delete(tag)
        }
    }

    private func usedTagIds(
        ignoringGoalsWithIds ignoredGoalIds: Set<UUID>,
    ) throws -> Set<UUID> {
        let goals = try fetchGoals()
        return Set(goals.lazy.filter { goal in
            !ignoredGoalIds.contains(goal.id)
        }
        .flatMap(\.tags)
        .map(\.id))
    }

    private func fetchGoals() throws -> [Goal] {
        try modelContext.fetch(FetchDescriptor<Goal>())
    }

    private func fetchTags() throws -> [Tag] {
        try modelContext.fetch(
            FetchDescriptor<Tag>(sortBy: [SortDescriptor<Tag>(\.normalizedName)]))
    }

    /// Captures the editable state of a goal before a write operation mutates it.
    ///
    /// `GoalSnapshot` lets `GoalManager` restore in-memory model values after a
    /// SwiftData save failure so the UI and model context return to the last
    /// successfully saved state.
    private struct GoalSnapshot {
        let name: String
        let details: String?
        let dueDate: Date?
        let earlyReminder: GoalReminder?
        let progress: GoalProgress
        let recurrence: GoalRecurrence?
        let tags: [Tag]

        init(goal: Goal) {
            name = goal.name
            details = goal.details
            dueDate = goal.dueDate
            earlyReminder = goal.earlyReminder
            progress = goal.progress
            recurrence = goal.recurrence
            tags = goal.tags
        }

        func restore(_ goal: Goal) {
            goal.name = name
            goal.details = details
            goal.dueDate = dueDate
            goal.earlyReminder = earlyReminder
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
