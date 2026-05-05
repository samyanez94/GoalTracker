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

    func updateGoal(_ updatedGoal: Goal) {
        guard let index = goals.firstIndex(where: { $0.id == updatedGoal.id }) else {
            return
        }
        goals[index] = updatedGoal
        saveGoals()
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
}
