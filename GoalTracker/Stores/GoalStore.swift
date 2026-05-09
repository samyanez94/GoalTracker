//
//  GoalStore.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class GoalStore {
    private(set) var goals: [Goal]

    @ObservationIgnored private let persistence: GoalPersistence

    @ObservationIgnored private let sorter: GoalSorter

    init(
        goals: [Goal]? = nil,
        persistence: GoalPersistence? = nil,
        sorter: GoalSorter? = nil
    ) {
        let persistence = persistence ?? GoalPersistence()
        self.persistence = persistence
        self.sorter = sorter ?? GoalSorter()
        self.goals = goals ?? Self.loadGoals(from: persistence)
    }

    func pendingGoals(sortedBy sortMode: GoalSortMode) -> [Goal] {
        sorter.sorted(
            goals.filter { !$0.isCompleted },
            by: sortMode,
        )
    }

    func completedGoals(sortedBy sortMode: GoalSortMode) -> [Goal] {
        sorter.sorted(
            goals.filter(\.isCompleted),
            by: sortMode,
        )
    }

    func addGoal(_ goal: Goal) {
        var goal = goal
        goal.sortOrder = sorter.nextSortOrder(
            in: goals,
            isCompleted: goal.isCompleted,
        )
        goals.append(goal)
        saveGoals()
    }

    @discardableResult
    func updateGoal(_ updatedGoal: Goal) -> Bool {
        guard let index = goals.firstIndex(where: { $0.id == updatedGoal.id }) else {
            return false
        }
        let isCompleted = goals[index].isCompleted
        var updatedGoal = updatedGoal
        if updatedGoal.isCompleted != isCompleted {
            updatedGoal.sortOrder = sorter.nextSortOrder(
                in: goals,
                isCompleted: updatedGoal.isCompleted,
            )
        }
        goals[index] = updatedGoal
        saveGoals()
        return true
    }

    @discardableResult
    func updateGoal(
        id: Goal.ID,
        name: String,
        description: String?,
        dueDate: Date?,
        completion: Goal.Completion,
    ) -> Bool {
        updateGoal(id: id) { goal in
            goal.name = name
            goal.description = description
            goal.dueDate = dueDate
            goal.completion = completion
            return true
        }
    }

    @discardableResult
    func toggleCompletion(id: Goal.ID) -> Bool {
        updateGoal(id: id) { goal in
            goal.toggleCompletion()
        }
    }

    @discardableResult
    func completeGoal(id: Goal.ID) -> Bool {
        updateGoal(id: id) { goal in
            goal.complete()
        }
    }

    @discardableResult
    func incrementProgress(id: Goal.ID) -> Bool {
        updateGoal(id: id) { goal in
            goal.incrementProgress()
        }
    }

    @discardableResult
    func decrementProgress(id: Goal.ID) -> Bool {
        updateGoal(id: id) { goal in
            goal.decrementProgress()
        }
    }

    func movePendingGoals(
        from source: IndexSet,
        to destination: Int,
        sortedBy sortMode: GoalSortMode = .manual,
    ) {
        moveGoals(
            matching: { !$0.isCompleted },
            from: source,
            to: destination,
            sortedBy: sortMode,
        )
    }

    func moveCompletedGoals(
        from source: IndexSet,
        to destination: Int,
        sortedBy sortMode: GoalSortMode = .manual,
    ) {
        moveGoals(
            matching: { $0.isCompleted },
            from: source,
            to: destination,
            sortedBy: sortMode,
        )
    }

    func deleteGoal(id: Goal.ID) {
        goals.removeAll { $0.id == id }
        saveGoals()
    }

    private static func loadGoals(from persistence: GoalPersistence) -> [Goal] {
        do {
            return try persistence.loadGoals()
        } catch {
            print("Failed to load goals: \(error)")
            return []
        }
    }

    private func saveGoals() {
        do {
            try persistence.saveGoals(goals)
        } catch {
            print("Failed to save goals: \(error)")
        }
    }

    private func moveGoals(
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
            guard let index = goals.firstIndex(where: { $0.id == goal.id }) else {
                continue
            }
            goals[index].sortOrder = sortOrder
        }
        saveGoals()
    }

    @discardableResult
    private func updateGoal(
        id: Goal.ID,
        _ mutate: (inout Goal) -> Bool,
    ) -> Bool {
        guard let index = goals.firstIndex(where: { $0.id == id }) else {
            return false
        }
        let isCompleted = goals[index].isCompleted
        var goal = goals[index]
        guard mutate(&goal) else {
            return false
        }
        if goal.isCompleted != isCompleted {
            goal.sortOrder = sorter.nextSortOrder(
                in: goals,
                isCompleted: goal.isCompleted,
            )
        }
        goals[index] = goal
        saveGoals()
        return true
    }
}
