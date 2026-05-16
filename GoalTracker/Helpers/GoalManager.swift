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

    private let saveContext: () throws -> Void

    private let rollbackContext: () -> Void

    private struct GoalSnapshot {
        let name: String
        let details: String?
        let dueDate: Date?
        let progress: GoalProgress

        init(goal: Goal) {
            name = goal.name
            details = goal.details
            dueDate = goal.dueDate
            progress = goal.progress
        }

        func restore(_ goal: Goal) {
            goal.name = name
            goal.details = details
            goal.dueDate = dueDate
            goal.progress = progress
        }
    }

    init(
        modelContext: ModelContext,
        saveContext: (() throws -> Void)? = nil,
        rollbackContext: (() -> Void)? = nil,
    ) {
        self.modelContext = modelContext
        self.saveContext = saveContext ?? { try modelContext.save() }
        self.rollbackContext = rollbackContext ?? { modelContext.rollback() }
    }

    func addGoal(
        _ goal: Goal,
    ) throws {
        modelContext.insert(goal)
        try saveChanges()
    }

    @discardableResult
    func updateGoal(
        _ goal: Goal,
        name: String,
        details: String?,
        dueDate: Date?,
        progress: GoalProgress,
    ) throws -> Bool {
        try updateGoal(goal) { goal in
            goal.name = name
            goal.details = details
            goal.dueDate = dueDate
            goal.progress = progress
            return true
        }
    }

    @discardableResult
    func toggleCompletion(
        _ goal: Goal,
    ) throws -> Bool {
        try updateProgress(goal) { goal in
            goal.toggleCompletion()
        }
    }

    @discardableResult
    func completeGoal(
        _ goal: Goal,
    ) throws -> Bool {
        try updateProgress(goal) { goal in
            goal.complete()
        }
    }

    @discardableResult
    func incrementProgress(
        _ goal: Goal,
    ) throws -> Bool {
        try updateProgress(goal) { goal in
            goal.incrementProgress()
        }
    }

    @discardableResult
    func decrementProgress(
        _ goal: Goal,
    ) throws -> Bool {
        try updateProgress(goal) { goal in
            goal.decrementProgress()
        }
    }

    func deleteGoal(_ goal: Goal) throws {
        modelContext.delete(goal)
        try saveDeletedGoal()
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

    private func saveDeletedGoal() throws {
        do {
            try saveContext()
        } catch {
            Task { @MainActor in
                rollbackContext()
            }
            throw SaveError.failed(error)
        }
    }

    @discardableResult
    private func updateGoal(
        _ goal: Goal,
        _ mutate: (Goal) -> Bool,
    ) throws -> Bool {
        let snapshot = GoalSnapshot(goal: goal)
        guard mutate(goal) else {
            return false
        }
        try saveChanges {
            snapshot.restore(goal)
        }
        return true
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
        try saveChanges {
            snapshot.restore(goal)
        }
        return true
    }
}
