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
    private let modelContext: ModelContext

    private let sorter: GoalSorter

    private let dateProvider: () -> Date

    init(
        modelContext: ModelContext,
        sorter: GoalSorter? = nil,
        dateProvider: @escaping () -> Date = Date.init,
    ) {
        self.modelContext = modelContext
        self.sorter = sorter ?? GoalSorter()
        self.dateProvider = dateProvider
    }

    func addGoal(
        _ goal: Goal,
        in goals: [Goal],
    ) {
        goal.sortOrder = sorter.nextSortOrder(
            in: goals,
            isCompleted: goal.isCompleted,
        )
        modelContext.insert(goal)
        saveChanges()
    }

    @discardableResult
    func updateGoal(
        id: Goal.ID,
        in goals: [Goal],
        name: String,
        details: String?,
        dueDate: Date?,
        progress: GoalProgress,
    ) -> Bool {
        updateGoal(id: id, in: goals) { goal in
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
    ) -> Bool {
        updateProgress(id: id, in: goals) { goal in
            goal.toggleCompletion()
        }
    }

    @discardableResult
    func completeGoal(
        id: Goal.ID,
        in goals: [Goal],
    ) -> Bool {
        updateProgress(id: id, in: goals) { goal in
            goal.complete()
        }
    }

    @discardableResult
    func incrementProgress(
        id: Goal.ID,
        in goals: [Goal],
    ) -> Bool {
        updateProgress(id: id, in: goals) { goal in
            goal.incrementProgress()
        }
    }

    @discardableResult
    func decrementProgress(
        id: Goal.ID,
        in goals: [Goal],
    ) -> Bool {
        updateProgress(id: id, in: goals) { goal in
            goal.decrementProgress()
        }
    }

    func movePendingGoals(
        in goals: [Goal],
        from source: IndexSet,
        to destination: Int,
        sortedBy sortMode: GoalSortMode = .manual,
    ) {
        moveGoals(
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
    ) {
        moveGoals(
            in: goals,
            matching: { $0.isCompleted },
            from: source,
            to: destination,
            sortedBy: sortMode,
        )
    }

    func deleteGoal(_ goal: Goal) {
        modelContext.delete(goal)
        saveChanges()
    }

    @discardableResult
    private func saveChanges() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            print("Failed to save goals: \(error)")
            return false
        }
    }

    private func moveGoals(
        in goals: [Goal],
        matching predicate: (Goal) -> Bool,
        from source: IndexSet,
        to destination: Int,
        sortedBy sortMode: GoalSortMode,
    ) {
        let sectionGoals = sorter.reorderedGoals(
            goals.filter(predicate),
            from: source,
            to: destination,
            sortedBy: sortMode,
        )
        for (sortOrder, goal) in sectionGoals.enumerated() {
            goal.sortOrder = sortOrder
        }
        saveChanges()
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
    ) -> Bool {
        guard let goal = goals.first(where: { $0.id == id }) else {
            return false
        }
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
        saveChanges()
        return true
    }

    @discardableResult
    private func updateProgress(
        id: Goal.ID,
        in goals: [Goal],
        _ mutate: (Goal) -> Bool,
    ) -> Bool {
        guard let goal = goals.first(where: { $0.id == id }) else {
            return false
        }
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
        saveChanges()
        return true
    }
}
