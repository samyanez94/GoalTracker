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
/// create, update, delete, reorder, or save a goal.
@MainActor
struct GoalManager {
    enum SaveError: LocalizedError {
        case failed(Error)

        var errorDescription: String? {
            "Your changes could not be saved."
        }
    }

    private let modelContext: ModelContext

    private let sorter: GoalSorter

    private let dateProvider: () -> Date

    private let saveContext: () throws -> Void

    private let rollbackContext: () -> Void

    private struct GoalSnapshot {
        let name: String
        let details: String?
        let dueDate: Date?
        let sortOrder: Int
        let progress: GoalProgress
        let progressEntries: [GoalProgressEntry]?

        init(goal: Goal) {
            name = goal.name
            details = goal.details
            dueDate = goal.dueDate
            sortOrder = goal.sortOrder
            progress = goal.progress
            progressEntries = goal.progressEntries
        }

        func restore(_ goal: Goal) {
            goal.name = name
            goal.details = details
            goal.dueDate = dueDate
            goal.sortOrder = sortOrder
            goal.progress = progress
            goal.progressEntries = progressEntries
        }
    }

    init(
        modelContext: ModelContext,
        sorter: GoalSorter? = nil,
        dateProvider: @escaping () -> Date = Date.init,
        saveContext: (() throws -> Void)? = nil,
        rollbackContext: (() -> Void)? = nil,
    ) {
        self.modelContext = modelContext
        self.sorter = sorter ?? GoalSorter()
        self.dateProvider = dateProvider
        self.saveContext = saveContext ?? { try modelContext.save() }
        self.rollbackContext = rollbackContext ?? { modelContext.rollback() }
    }

    func addGoal(
        _ goal: Goal,
        in goals: [Goal],
    ) throws {
        goal.sortOrder = sorter.nextSortOrder(
            in: goals,
            isCompleted: goal.isCompleted,
        )
        modelContext.insert(goal)
        try saveChanges()
    }

    @discardableResult
    func updateGoal(
        id: Goal.ID,
        in goals: [Goal],
        name: String,
        details: String?,
        dueDate: Date?,
        progress: GoalProgress,
    ) throws -> Bool {
        try updateGoal(id: id, in: goals) { goal in
            let previousProgress = goal.progress
            goal.name = name
            goal.details = details
            goal.dueDate = dueDate
            goal.progress = progress
            if let progressAmount = progressHistoryAmount(
                from: previousProgress,
                to: progress,
            ) {
                recordProgressChange(
                    for: goal,
                    amount: progressAmount,
                )
            }
            return true
        }
    }

    @discardableResult
    func toggleCompletion(
        id: Goal.ID,
        in goals: [Goal],
    ) throws -> Bool {
        try updateProgress(id: id, in: goals) { goal in
            goal.toggleCompletion()
        }
    }

    @discardableResult
    func completeGoal(
        id: Goal.ID,
        in goals: [Goal],
    ) throws -> Bool {
        try updateProgress(id: id, in: goals) { goal in
            goal.complete()
        }
    }

    @discardableResult
    func incrementProgress(
        id: Goal.ID,
        in goals: [Goal],
    ) throws -> Bool {
        try updateProgress(id: id, in: goals) { goal in
            goal.incrementProgress()
        }
    }

    @discardableResult
    func decrementProgress(
        id: Goal.ID,
        in goals: [Goal],
    ) throws -> Bool {
        try updateProgress(id: id, in: goals) { goal in
            goal.decrementProgress()
        }
    }

    func movePendingGoals(
        in goals: [Goal],
        from source: IndexSet,
        to destination: Int,
        sortedBy sortMode: GoalSortMode = .manual,
    ) throws {
        try moveGoals(
            in: goals,
            matching: { !$0.isCompleted },
            from: source,
            to: destination,
            sortedBy: sortMode,
        )
    }

    func moveCompletedGoals(
        in goals: [Goal],
        from source: IndexSet,
        to destination: Int,
        sortedBy sortMode: GoalSortMode = .manual,
    ) throws {
        try moveGoals(
            in: goals,
            matching: { $0.isCompleted },
            from: source,
            to: destination,
            sortedBy: sortMode,
        )
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

    private func moveGoals(
        in goals: [Goal],
        matching predicate: (Goal) -> Bool,
        from source: IndexSet,
        to destination: Int,
        sortedBy sortMode: GoalSortMode,
    ) throws {
        let sectionGoals = sorter.reorderedGoals(
            goals.filter(predicate),
            from: source,
            to: destination,
            sortedBy: sortMode,
        )
        let sortOrderSnapshots = sectionGoals.map { goal in
            (goal, goal.sortOrder)
        }
        for (sortOrder, goal) in sectionGoals.enumerated() {
            goal.sortOrder = sortOrder
        }
        try saveChanges {
            for (goal, sortOrder) in sortOrderSnapshots {
                goal.sortOrder = sortOrder
            }
        }
    }

    private func recordProgressChange(
        for goal: Goal,
        amount: Double,
    ) {
        guard amount != 0 else {
            return
        }
        let entry = GoalProgressEntry(
            date: dateProvider(),
            amount: amount,
            goal: goal,
        )
        modelContext.insert(entry)
        if goal.progressEntries == nil {
            goal.progressEntries = []
        }
        goal.progressEntries?.append(entry)
    }

    private func progressHistoryAmount(
        from previousProgress: GoalProgress,
        to progress: GoalProgress,
    ) -> Double? {
        guard previousProgress.isMeasurable,
            progress.isMeasurable
        else {
            return nil
        }
        let amount = progress.currentValue - previousProgress.currentValue
        guard amount != 0 else {
            return nil
        }
        return amount
    }

    @discardableResult
    private func updateGoal(
        id: Goal.ID,
        in goals: [Goal],
        _ mutate: (Goal) -> Bool,
    ) throws -> Bool {
        guard let goal = goals.first(where: { $0.id == id }) else {
            return false
        }
        let snapshot = GoalSnapshot(goal: goal)
        let isCompleted = goal.isCompleted
        guard mutate(goal) else {
            return false
        }
        if goal.isCompleted != isCompleted {
            goal.sortOrder = sorter.nextSortOrder(
                in: goals,
                isCompleted: goal.isCompleted,
            )
        }
        try saveChanges {
            snapshot.restore(goal)
        }
        return true
    }

    @discardableResult
    private func updateProgress(
        id: Goal.ID,
        in goals: [Goal],
        _ mutate: (Goal) -> Bool,
    ) throws -> Bool {
        guard let goal = goals.first(where: { $0.id == id }) else {
            return false
        }
        let snapshot = GoalSnapshot(goal: goal)
        let isCompleted = goal.isCompleted
        let isMeasurable = goal.progress.isMeasurable
        let currentValue = goal.progress.currentValue
        guard mutate(goal) else {
            return false
        }
        if isMeasurable {
            recordProgressChange(
                for: goal,
                amount: goal.progress.currentValue - currentValue,
            )
        }
        if goal.isCompleted != isCompleted {
            goal.sortOrder = sorter.nextSortOrder(
                in: goals,
                isCompleted: goal.isCompleted,
            )
        }
        try saveChanges {
            snapshot.restore(goal)
        }
        return true
    }
}
