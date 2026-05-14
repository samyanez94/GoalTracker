//
//  GoalStore.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class GoalStore {
    private(set) var goals: [Goal]

    @ObservationIgnored private let modelContainer: ModelContainer?

    @ObservationIgnored private let modelContext: ModelContext

    @ObservationIgnored private let sorter: GoalSorter

    init(
        modelContext: ModelContext,
        sorter: GoalSorter? = nil,
    ) {
        modelContainer = nil
        self.modelContext = modelContext
        self.sorter = sorter ?? GoalSorter()
        goals = Self.fetchGoals(from: modelContext)
    }

    init(
        goals: [Goal] = [],
        sorter: GoalSorter? = nil,
    ) {
        let modelContainer = Self.makeInMemoryContainer()
        let modelContext = modelContainer.mainContext
        for goal in goals {
            modelContext.insert(goal)
        }
        try? modelContext.save()
        self.modelContainer = modelContainer
        self.modelContext = modelContext
        self.sorter = sorter ?? GoalSorter()
        self.goals = Self.fetchGoals(from: modelContext)
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
        goal.sortOrder = sorter.nextSortOrder(
            in: goals,
            isCompleted: goal.isCompleted,
        )
        modelContext.insert(goal)
        goals.append(goal)
        saveChanges()
    }

    @discardableResult
    func updateGoal(_ updatedGoal: Goal) -> Bool {
        guard let index = goals.firstIndex(where: { $0.id == updatedGoal.id }) else {
            return false
        }
        let goal = goals[index]
        let isCompleted = goal.isCompleted
        goal.name = updatedGoal.name
        goal.details = updatedGoal.details
        goal.dueDate = updatedGoal.dueDate
        goal.progress = updatedGoal.progress
        if goal.isCompleted != isCompleted {
            goal.sortOrder = sorter.nextSortOrder(
                in: goals,
                isCompleted: goal.isCompleted,
            )
        } else {
            goal.sortOrder = updatedGoal.sortOrder
        }
        goals[index] = goal
        saveChanges()
        return true
    }

    @discardableResult
    func updateGoal(
        id: Goal.ID,
        name: String,
        details: String?,
        dueDate: Date?,
        progress: GoalProgress,
    ) -> Bool {
        updateGoal(id: id) { goal in
            goal.name = name
            goal.details = details
            goal.dueDate = dueDate
            goal.progress = progress
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
        guard let index = goals.firstIndex(where: { $0.id == id }) else {
            return
        }
        let goal = goals.remove(at: index)
        modelContext.delete(goal)
        saveChanges()
    }

    private static func makeInMemoryContainer() -> ModelContainer {
        do {
            return try ModelContainer(
                for: Goal.self,
                GoalProgressEntry.self,
                configurations: ModelConfiguration(
                    UUID().uuidString,
                    isStoredInMemoryOnly: true,
                ),
            )
        } catch {
            preconditionFailure("Failed to create in-memory model container: \(error)")
        }
    }

    private static func fetchGoals(from modelContext: ModelContext) -> [Goal] {
        do {
            return try modelContext.fetch(FetchDescriptor<Goal>())
        } catch {
            print("Failed to fetch goals: \(error)")
            return []
        }
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
            goal.sortOrder = sortOrder
            goals[index] = goal
        }
        saveChanges()
    }

    @discardableResult
    private func updateGoal(
        id: Goal.ID,
        _ mutate: (Goal) -> Bool,
    ) -> Bool {
        guard let index = goals.firstIndex(where: { $0.id == id }) else {
            return false
        }
        let isCompleted = goals[index].isCompleted
        let goal = goals[index]
        guard mutate(goal) else {
            return false
        }
        if goal.isCompleted != isCompleted {
            goal.sortOrder = sorter.nextSortOrder(
                in: goals,
                isCompleted: goal.isCompleted,
            )
        }
        goals[index] = goal
        saveChanges()
        return true
    }
}
