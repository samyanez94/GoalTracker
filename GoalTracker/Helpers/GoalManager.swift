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
    enum SaveError: LocalizedError {
        case failed(Error)

        var errorDescription: String? {
            "Your changes could not be saved."
        }
    }

    private let modelContext: ModelContext

    private let notificationScheduler: any GoalReminderScheduling

    private let saveContext: () throws -> Void

    private let rollbackContext: () -> Void

    private struct GoalSnapshot {
        let name: String
        let details: String?
        let dueDate: Date?
        let reminder: GoalReminder?
        let progress: GoalProgress
        let tags: [Tag]

        init(goal: Goal) {
            name = goal.name
            details = goal.details
            dueDate = goal.dueDate
            reminder = goal.reminder
            progress = goal.progress
            tags = goal.tags
        }

        func restore(_ goal: Goal) {
            goal.name = name
            goal.details = details
            goal.dueDate = dueDate
            goal.reminder = reminder
            goal.progress = progress
            goal.tags = tags
        }
    }

    init(
        modelContext: ModelContext,
        notificationScheduler: any GoalReminderScheduling = GoalNotificationScheduler(),
        saveContext: (() throws -> Void)? = nil,
        rollbackContext: (() -> Void)? = nil,
    ) {
        self.modelContext = modelContext
        self.notificationScheduler = notificationScheduler
        self.saveContext = saveContext ?? { try modelContext.save() }
        self.rollbackContext = rollbackContext ?? { modelContext.rollback() }
    }

    /// Inserts a new goal into the model context and saves the change.
    func addGoal(
        _ goal: Goal,
    ) async throws {
        modelContext.insert(goal)
        try saveChanges()
        await syncReminder(for: goal)
    }

    /// Updates a goal's editable fields, cleans up unused tags, and saves the change.
    ///
    /// When `tags` is provided, the goal's tag relationship is replaced and any
    /// tags that are no longer attached to a goal are deleted.
    ///
    /// - Returns: `true` when the goal was mutated and saved.
    @discardableResult
    func updateGoal(
        _ goal: Goal,
        name: String,
        details: String?,
        dueDate: Date?,
        reminder: GoalReminder? = nil,
        progress: GoalProgress,
        tags: [Tag]? = nil,
    ) async throws -> Bool {
        let snapshot = GoalSnapshot(goal: goal)
        let previousTags = goal.tags
        do {
            goal.name = name
            goal.details = details
            goal.dueDate = dueDate
            goal.reminder = reminder
            goal.progress = progress
            if let tags {
                goal.tags = tags
                try deleteUnusedTags(
                    from: previousTags + tags,
                    excluding: tags,
                )
            }
            try saveContext()
        } catch {
            rollbackContext()
            snapshot.restore(goal)
            throw SaveError.failed(error)
        }
        await syncReminder(for: goal)
        return true
    }

    /// Toggles a goal between completed and incomplete states, then saves the change.
    ///
    /// - Returns: `true` when the goal's progress changed.
    @discardableResult
    func toggleCompletion(
        _ goal: Goal,
    ) async throws -> Bool {
        try await updateProgress(goal) { goal in
            goal.toggleCompletion()
        }
    }

    /// Marks a goal as complete and saves the change.
    ///
    /// - Returns: `true` when the goal's progress changed.
    @discardableResult
    func completeGoal(
        _ goal: Goal,
    ) async throws -> Bool {
        try await updateProgress(goal) { goal in
            goal.complete()
        }
    }

    /// Advances a measurable goal by its configured step and saves the change.
    ///
    /// - Returns: `true` when the goal's progress changed.
    @discardableResult
    func incrementProgress(
        _ goal: Goal,
    ) async throws -> Bool {
        try await updateProgress(goal) { goal in
            goal.incrementProgress()
        }
    }

    /// Reduces a measurable goal by its configured step and saves the change.
    ///
    /// - Returns: `true` when the goal's progress changed.
    @discardableResult
    func decrementProgress(
        _ goal: Goal,
    ) async throws -> Bool {
        try await updateProgress(goal) { goal in
            goal.decrementProgress()
        }
    }

    /// Deletes a single goal and removes any of its tags that are no longer used.
    func deleteGoal(_ goal: Goal) async throws {
        try await deleteGoals([goal])
    }

    /// Deletes a tag and saves the change.
    ///
    /// SwiftData updates goal relationships for the deleted tag.
    func deleteTag(_ tag: Tag) throws {
        modelContext.delete(tag)
        try saveChanges()
    }

    /// Deletes multiple goals and removes any tags that are no longer used.
    func deleteGoals(_ goals: [Goal]) async throws {
        let deletedGoalIds = Set(goals.map(\.id))
        let candidateTags = goals.flatMap(\.tags)
        for goal in goals {
            modelContext.delete(goal)
        }
        try saveDeletionChanges {
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
        try saveDeletionChanges {
            try deleteUnusedTags(
                from: fetchTags(),
                excluding: protectedTags,
            )
        }
    }

    private func saveChanges(
        restoreOnFailure: () -> Void = {},
    ) throws {
        do {
            try saveContext()
        } catch {
            rollbackContext()
            restoreOnFailure()
            throw SaveError.failed(error)
        }
    }

    private func saveDeletionChanges(
        beforeSave: () throws -> Void = {},
    ) throws {
        do {
            try beforeSave()
            try saveContext()
        } catch {
            rollbackContext()
            throw SaveError.failed(error)
        }
    }

    @discardableResult
    private func updateProgress(
        _ goal: Goal,
        _ mutate: (Goal) -> Bool,
    ) async throws -> Bool {
        let snapshot = GoalSnapshot(goal: goal)
        guard mutate(goal) else {
            return false
        }
        try saveChanges {
            snapshot.restore(goal)
        }
        await syncReminder(for: goal)
        return true
    }

    private func syncReminder(for goal: Goal) async {
        guard !goal.isCompleted,
              goal.dueDate != nil,
              goal.reminder != nil else {
            notificationScheduler.cancelReminder(for: goal.id)
            return
        }
        _ = try? await notificationScheduler.scheduleReminder(for: goal)
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
}
