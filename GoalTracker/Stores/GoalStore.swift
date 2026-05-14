//
//  GoalStore.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation
import SwiftData

@MainActor
struct GoalStore {
    private let modelContext: ModelContext

    private let sorter: GoalSorter

    init(
        modelContext: ModelContext,
        sorter: GoalSorter? = nil,
    ) {
        self.modelContext = modelContext
        self.sorter = sorter ?? GoalSorter()
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
            goal.name = name
            goal.details = details
            goal.dueDate = dueDate
            goal.progress = progress
            return true
        }
    }

    @discardableResult
    func toggleCompletion(
        id: Goal.ID,
        in goals: [Goal],
    ) -> Bool {
        updateGoal(id: id, in: goals) { goal in
            goal.toggleCompletion()
        }
    }

    @discardableResult
    func completeGoal(
        id: Goal.ID,
        in goals: [Goal],
    ) -> Bool {
        updateGoal(id: id, in: goals) { goal in
            goal.complete()
        }
    }

    @discardableResult
    func incrementProgress(
        id: Goal.ID,
        in goals: [Goal],
    ) -> Bool {
        updateGoal(id: id, in: goals) { goal in
            goal.incrementProgress()
        }
    }

    @discardableResult
    func decrementProgress(
        id: Goal.ID,
        in goals: [Goal],
    ) -> Bool {
        updateGoal(id: id, in: goals) { goal in
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
}
