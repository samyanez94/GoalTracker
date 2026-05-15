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
    private let entryDate = Date(timeIntervalSinceReferenceDate: 123)

    @Test
    func `Incrementing measurable progress writes a positive history entry`() throws {
        let container = try makeContainer()
        let goal = makeGoal(
            progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
        )
        insert(goal, into: container)
        let manager = makeManager(in: container)

        let didChange = try manager.incrementProgress(goal)

        let entry = try #require(fetchEntries(in: container).first)
        #expect(didChange)
        #expect(entry.amount == 2)
        #expect(entry.date == entryDate)
        #expect(entry.goal?.id == goal.id)
        #expect(goal.progressEntries?.count == 1)
    }

    @Test
    func `Decrementing measurable progress writes a negative history entry`() throws {
        let container = try makeContainer()
        let goal = makeGoal(
            progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
        )
        insert(goal, into: container)
        let manager = makeManager(in: container)

        let didChange = try manager.decrementProgress(goal)

        let entry = try #require(fetchEntries(in: container).first)
        #expect(didChange)
        #expect(entry.amount == -2)
        #expect(entry.date == entryDate)
    }

    @Test
    func `Completing measurable progress writes the remaining delta`() throws {
        let container = try makeContainer()
        let goal = makeGoal(
            progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
        )
        insert(goal, into: container)
        let manager = makeManager(in: container)

        let didChange = try manager.completeGoal(goal)

        let entry = try #require(fetchEntries(in: container).first)
        #expect(didChange)
        #expect(entry.amount == 6)
        #expect(goal.progress.currentValue == 10)
    }

    @Test
    func `Resetting measurable progress writes a negative current value delta`() throws {
        let container = try makeContainer()
        let goal = makeGoal(
            progress: .measurable(currentValue: 10, targetValue: 10, step: 2),
        )
        insert(goal, into: container)
        let manager = makeManager(in: container)

        let didChange = try manager.toggleCompletion(goal)

        let entry = try #require(fetchEntries(in: container).first)
        #expect(didChange)
        #expect(entry.amount == -10)
        #expect(goal.progress.currentValue == 0)
    }

    @Test
    func `Outcome goals do not write progress history entries`() throws {
        let container = try makeContainer()
        let goal = makeGoal(progress: .outcomePending)
        insert(goal, into: container)
        let manager = makeManager(in: container)

        let didChange = try manager.completeGoal(goal)

        #expect(didChange)
        #expect(try fetchEntries(in: container).isEmpty)
    }

    @Test
    func `Editing measurable current value writes a history entry`() throws {
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

        let entry = try #require(fetchEntries(in: container).first)
        #expect(didChange)
        #expect(entry.amount == 3)
    }

    @Test
    func `Editing measurable target only does not write a history entry`() throws {
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
        #expect(try fetchEntries(in: container).isEmpty)
    }

    @Test
    func `Deleting a goal cascades progress history entries`() throws {
        let container = try makeContainer()
        let goal = makeGoal(
            progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
        )
        insert(goal, into: container)
        let manager = makeManager(in: container)
        try manager.incrementProgress(goal)

        try manager.deleteGoal(goal)

        #expect(try fetchEntries(in: container).isEmpty)
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
            dateProvider: { entryDate },
            saveContext: {
                throw TestSaveError.failed
            },
        )

        #expect(throws: GoalManager.SaveError.self) {
            try manager.incrementProgress(goal)
        }
        #expect(goal.progress.currentValue == 4)
        #expect(try fetchEntries(in: container).isEmpty)
    }

    private func makeContainer() throws -> ModelContainer {
        try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
    }

    private func makeManager(in container: ModelContainer) -> GoalManager {
        GoalManager(
            modelContext: container.mainContext,
            dateProvider: { entryDate },
        )
    }

    private func insert(
        _ goal: Goal,
        into container: ModelContainer,
    ) {
        container.mainContext.insert(goal)
        try? container.mainContext.save()
    }

    private func fetchEntries(in container: ModelContainer) throws -> [GoalProgressEntry] {
        try container.mainContext.fetch(FetchDescriptor<GoalProgressEntry>())
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
