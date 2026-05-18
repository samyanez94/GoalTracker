//
//  GoalManagerTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation
import SwiftData
import Testing

@testable import GoalTracker

@MainActor
struct GoalManagerTests {
    @Test
    func `Incrementing measurable progress updates current value`() throws {
        let container = try makeContainer()
        let goal = makeGoal(
            progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
        )
        insert(goal, into: container)
        let manager = makeManager(in: container)

        let didChange = try manager.incrementProgress(goal)

        #expect(didChange)
        #expect(goal.progress.currentValue == 6)
    }

    @Test
    func `Completing outcome goal updates completion state`() throws {
        let container = try makeContainer()
        let goal = makeGoal(progress: .outcomePending)
        insert(goal, into: container)
        let manager = makeManager(in: container)

        let didChange = try manager.completeGoal(goal)

        #expect(didChange)
        #expect(goal.progress.isCompleted)
    }

    @Test
    func `Editing measurable current value updates progress`() throws {
        let container = try makeContainer()
        let goal = makeGoal(
            progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
        )
        insert(goal, into: container)
        let manager = makeManager(in: container)

        let didChange = try manager.updateGoal(
            goal,
            name: goal.name,
            details: goal.details,
            dueDate: goal.dueDate,
            progress: .measurable(currentValue: 7, targetValue: 10, step: 2),
        )

        #expect(didChange)
        #expect(goal.progress.currentValue == 7)
    }

    @Test
    func `Deleting a goal removes it from the model context`() throws {
        let container = try makeContainer()
        let goal = makeGoal(
            progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
        )
        insert(goal, into: container)
        let manager = makeManager(in: container)

        try manager.deleteGoal(goal)

        #expect(try fetchGoals(in: container).isEmpty)
    }

    @Test
    func `Deleting multiple goals removes them from the model context`() throws {
        let container = try makeContainer()
        let firstGoal = makeGoal(
            name: "First Goal",
            progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
        )
        let secondGoal = makeGoal(
            name: "Second Goal",
            progress: .outcomePending,
        )
        let retainedGoal = makeGoal(
            name: "Retained Goal",
            progress: .outcomeCompleted,
        )
        insert(firstGoal, into: container)
        insert(secondGoal, into: container)
        insert(retainedGoal, into: container)
        let manager = makeManager(in: container)

        try manager.deleteGoals([firstGoal, secondGoal])

        let remainingGoalIDs = try Set(fetchGoals(in: container).map(\.id))
        #expect(remainingGoalIDs == [retainedGoal.id])
    }

    @Test
    func `Bulk delete save failure rolls back deletions and throws`() throws {
        let container = try makeContainer()
        let firstGoal = makeGoal(
            name: "First Goal",
            progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
        )
        let secondGoal = makeGoal(
            name: "Second Goal",
            progress: .outcomePending,
        )
        insert(firstGoal, into: container)
        insert(secondGoal, into: container)
        let manager = GoalManager(
            modelContext: container.mainContext,
            saveContext: {
                throw TestSaveError.failed
            },
        )

        #expect(throws: GoalManager.SaveError.self) {
            try manager.deleteGoals([firstGoal, secondGoal])
        }

        let remainingGoalIDs = try Set(fetchGoals(in: container).map(\.id))
        #expect(remainingGoalIDs == [firstGoal.id, secondGoal.id])
    }

    @Test
    func `Save failure rolls back progress changes and throws`() throws {
        let container = try makeContainer()
        let goal = makeGoal(
            progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
        )
        insert(goal, into: container)
        let manager = GoalManager(
            modelContext: container.mainContext,
            saveContext: {
                throw TestSaveError.failed
            },
        )

        #expect(throws: GoalManager.SaveError.self) {
            try manager.incrementProgress(goal)
        }
        #expect(goal.progress.currentValue == 4)
    }

    private func makeContainer() throws -> ModelContainer {
        try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
    }

    private func makeManager(in container: ModelContainer) -> GoalManager {
        GoalManager(modelContext: container.mainContext)
    }

    private func insert(
        _ goal: Goal,
        into container: ModelContainer,
    ) {
        container.mainContext.insert(goal)
        try? container.mainContext.save()
    }

    private func fetchGoals(in container: ModelContainer) throws -> [Goal] {
        try container.mainContext.fetch(FetchDescriptor<Goal>())
    }

    private func makeGoal(
        name: String = "Test Goal",
        progress: GoalProgress,
    ) -> Goal {
        Goal(
            name: name,
            details: nil,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            progress: progress,
        )
    }

    private enum TestSaveError: Error {
        case failed
    }
}
