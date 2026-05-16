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
    func `Decrementing measurable progress updates current value`() throws {
        let container = try makeContainer()
        let goal = makeGoal(
            progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
        )
        insert(goal, into: container)
        let manager = makeManager(in: container)

        let didChange = try manager.decrementProgress(goal)

        #expect(didChange)
        #expect(goal.progress.currentValue == 2)
    }

    @Test
    func `Completing measurable progress sets current value to target`() throws {
        let container = try makeContainer()
        let goal = makeGoal(
            progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
        )
        insert(goal, into: container)
        let manager = makeManager(in: container)

        let didChange = try manager.completeGoal(goal)

        #expect(didChange)
        #expect(goal.progress.currentValue == 10)
    }

    @Test
    func `Toggling completed measurable progress resets current value`() throws {
        let container = try makeContainer()
        let goal = makeGoal(
            progress: .measurable(currentValue: 10, targetValue: 10, step: 2),
        )
        insert(goal, into: container)
        let manager = makeManager(in: container)

        let didChange = try manager.toggleCompletion(goal)

        #expect(didChange)
        #expect(goal.progress.currentValue == 0)
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
    func `Editing measurable target only updates target value`() throws {
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
            progress: .measurable(currentValue: 4, targetValue: 12, step: 2),
        )

        #expect(didChange)
        #expect(goal.progress.currentValue == 4)
        #expect(goal.progress.targetValue == 12)
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

    private func makeGoal(progress: GoalProgress) -> Goal {
        Goal(
            name: "Test Goal",
            details: nil,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            progress: progress,
        )
    }

    private enum TestSaveError: Error {
        case failed
    }
}
