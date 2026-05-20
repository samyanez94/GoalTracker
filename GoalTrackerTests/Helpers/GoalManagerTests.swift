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
    func `Editing goal updates selected tags`() throws {
        let container = try makeContainer()
        let goal = makeGoal(progress: .outcomePending)
        let healthTag = Tag(name: "Health")
        let runningTag = Tag(name: "Running")
        insert(goal, into: container)
        let manager = makeManager(in: container)

        let didChange = try manager.updateGoal(
            goal,
            name: goal.name,
            details: goal.details,
            dueDate: goal.dueDate,
            progress: goal.progress,
            tags: [healthTag, runningTag],
        )

        #expect(didChange)
        #expect(Set(goal.tags.map(\.name)) == ["Health", "Running"])
    }

    @Test
    func `Editing goal deletes tags that are no longer used`() throws {
        let container = try makeContainer()
        let oldTag = Tag(name: "Old")
        let newTag = Tag(name: "New")
        let goal = makeGoal(progress: .outcomePending)
        goal.tags = [oldTag]
        insert(goal, into: container)
        container.mainContext.insert(newTag)
        try container.mainContext.save()
        let manager = makeManager(in: container)

        _ = try manager.updateGoal(
            goal,
            name: goal.name,
            details: goal.details,
            dueDate: goal.dueDate,
            progress: goal.progress,
            tags: [newTag],
        )

        #expect(Set(try fetchTags(in: container).map(\.name)) == ["New"])
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
    func `Deleting a goal deletes tags that are no longer used`() throws {
        let container = try makeContainer()
        let tag = Tag(name: "Solo")
        let goal = makeGoal(progress: .outcomePending)
        goal.tags = [tag]
        insert(goal, into: container)
        let manager = makeManager(in: container)

        try manager.deleteGoal(goal)

        #expect(try fetchGoals(in: container).isEmpty)
        #expect(try fetchTags(in: container).isEmpty)
    }

    @Test
    func `Deleting a goal keeps tags used by another goal`() throws {
        let container = try makeContainer()
        let tag = Tag(name: "Shared")
        let deletedGoal = makeGoal(name: "Deleted Goal", progress: .outcomePending)
        let retainedGoal = makeGoal(name: "Retained Goal", progress: .outcomePending)
        deletedGoal.tags = [tag]
        retainedGoal.tags = [tag]
        insert(deletedGoal, into: container)
        insert(retainedGoal, into: container)
        let manager = makeManager(in: container)

        try manager.deleteGoal(deletedGoal)

        #expect(try fetchGoals(in: container).map(\.id) == [retainedGoal.id])
        #expect(try fetchTags(in: container).map(\.name) == ["Shared"])
    }

    @Test
    func `Deleting a tag removes it from goals`() throws {
        let container = try makeContainer()
        let tag = Tag(name: "Health")
        let goal = makeGoal(progress: .outcomePending)
        goal.tags = [tag]
        insert(goal, into: container)
        let manager = makeManager(in: container)

        try manager.deleteTag(tag)

        let fetchedGoal = try #require(try fetchGoals(in: container).first)
        #expect(try fetchTags(in: container).isEmpty)
        #expect(fetchedGoal.tags.isEmpty)
    }

    @Test
    func `Deleting unused tags keeps protected form selections`() throws {
        let container = try makeContainer()
        let protectedTag = Tag(name: "Selected")
        let unusedTag = Tag(name: "Unused")
        container.mainContext.insert(protectedTag)
        container.mainContext.insert(unusedTag)
        try container.mainContext.save()
        let manager = makeManager(in: container)

        try manager.deleteUnusedTags(excluding: [protectedTag])

        #expect(try fetchTags(in: container).map(\.name) == ["Selected"])
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

    private func fetchTags(in container: ModelContainer) throws -> [GoalTrackerSchemaV1.Tag] {
        try container.mainContext.fetch(
            FetchDescriptor<GoalTrackerSchemaV1.Tag>(
                sortBy: [SortDescriptor<GoalTrackerSchemaV1.Tag>(\.normalizedName)],
            ),
        )
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
