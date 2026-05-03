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

    @ObservationIgnored private let fileURL: URL

    var pendingGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }

    var completedGoals: [Goal] {
        goals.filter(\.isCompleted)
    }

    private static var defaultFileURL: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "GoalTracker", directoryHint: .isDirectory)
            .appending(path: "goals.json")
    }

    init(goals: [Goal]? = nil, fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL
        self.goals = goals ?? Self.loadGoals(from: self.fileURL)
    }

    func addGoal(name: String, description: String?, progress: Goal.Progress) {
        let goal = Goal(
            name: name,
            description: description,
            createdAt: Date(),
            progress: progress,
        )
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

    private static func loadGoals(from fileURL: URL) -> [Goal] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([Goal].self, from: data)
        } catch {
            print("Failed to load goals: \(error)")
            return []
        }
    }

    private func saveGoals() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
            )
            let data = try JSONEncoder().encode(goals)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            print("Failed to save goals: \(error)")
        }
    }
}
