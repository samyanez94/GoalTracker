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

    var pendingGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }

    var completedGoals: [Goal] {
        goals.filter(\.isCompleted)
    }

    init(goals: [Goal] = []) {
        self.goals = goals
    }

    func addGoal(name: String, description: String?) {
        let goal = Goal(
            name: name,
            description: description,
            createdAt: Date(),
            isCompleted: false,
        )
        goals.append(goal)
    }

    func updateGoal(_ updatedGoal: Goal) {
        guard let index = goals.firstIndex(where: { $0.id == updatedGoal.id }) else {
            return
        }

        goals[index] = updatedGoal
    }

    func deleteGoal(id: Goal.ID) {
        goals.removeAll { $0.id == id }
    }
}
