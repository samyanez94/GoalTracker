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

    var pendingGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }

    var completedGoals: [Goal] {
        goals.filter(\.isCompleted)
    }

    init(
        goals: [Goal]? = nil,
        persistence: GoalPersistence? = nil,
    ) {
        let persistence = persistence ?? GoalPersistence()
        self.persistence = persistence
        self.goals = goals ?? Self.loadGoals(from: persistence)
    }

    func addGoal(_ goal: Goal) {
        goals.append(goal)
        saveGoals()
    }

    @discardableResult
    func updateGoal(_ updatedGoal: Goal) -> Bool {
        guard let index = goals.firstIndex(where: { $0.id == updatedGoal.id }) else {
            return false
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

    @discardableResult
    private func updateGoal(
        id: Goal.ID,
        _ mutate: (inout Goal) -> Bool,
    ) -> Bool {
        guard let index = goals.firstIndex(where: { $0.id == id }) else {
            return false
        }
        var goal = goals[index]
        guard mutate(&goal) else {
            return false
        }
        goals[index] = goal
        saveGoals()
        return true
    }
}
