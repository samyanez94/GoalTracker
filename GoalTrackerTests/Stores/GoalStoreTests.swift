//
//  GoalStoreTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/12/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalStoreTests {
  @Test
  func `Initializes with provided goals instead of loading persisted goals`() throws {
    let fixture = try StoreFixture(persistedGoals: [goal(named: "Persisted")])
    let providedGoal = goal(named: "Provided")

    let store = GoalStore(goals: [providedGoal], persistence: fixture.persistence)

    #expect(store.goals.map(\.name) == ["Provided"])
  }

  @Test
  func `Initializes by loading persisted goals when goals are not provided`() throws {
    let persistedGoals = [
      goal(named: "First", sortOrder: 0),
      goal(named: "Second", sortOrder: 1),
    ]
    let fixture = try StoreFixture(persistedGoals: persistedGoals)

    let store = GoalStore(persistence: fixture.persistence)

    #expect(store.goals.map(\.id) == persistedGoals.map(\.id))
  }

  @Test
  func `Add goal assigns next sort order for its completion section and saves`() throws {
    let completedGoal = goal(
      named: "Completed",
      sortOrder: 8,
      progress: .outcomeCompleted,
    )
    let pendingGoal = goal(named: "Pending", sortOrder: 2)
    let fixture = try StoreFixture()
    let store = GoalStore(
      goals: [completedGoal, pendingGoal],
      persistence: fixture.persistence,
    )

    store.addGoal(goal(named: "New Pending", sortOrder: 99))

    let addedGoal = try #require(store.goals.last)
    #expect(addedGoal.name == "New Pending")
    #expect(addedGoal.sortOrder == 3)
    #expect(try fixture.savedGoals().map(\.name) == ["Completed", "Pending", "New Pending"])
  }

  @Test
  func `Update goal changes existing values and saves`() throws {
    let originalGoal = goal(named: "Original")
    let fixture = try StoreFixture()
    let store = GoalStore(goals: [originalGoal], persistence: fixture.persistence)
    let updatedGoal = Goal(
      id: originalGoal.id,
      name: "Updated",
      description: "Updated description",
      dueDate: date(4),
      createdAt: originalGoal.createdAt,
      sortOrder: originalGoal.sortOrder,
      progress: .outcomePending,
    )

    let didUpdate = store.updateGoal(updatedGoal)

    #expect(didUpdate)
    #expect(store.goals.first?.name == "Updated")
    #expect(store.goals.first?.description == "Updated description")
    #expect(try fixture.savedGoals().first?.name == "Updated")
  }

  @Test
  func `Update goal returns false and does not save when id is missing`() throws {
    let originalGoal = goal(named: "Original")
    let fixture = try StoreFixture()
    let store = GoalStore(goals: [originalGoal], persistence: fixture.persistence)
    let missingGoal = goal(named: "Missing")

    let didUpdate = store.updateGoal(missingGoal)

    #expect(didUpdate == false)
    #expect(store.goals.map(\.id) == [originalGoal.id])
    #expect(try fixture.savedGoals().isEmpty)
  }

  @Test
  func `Updating completion moves goal to end of new completion section`() throws {
    let pendingGoal = goal(named: "Pending", sortOrder: 1)
    let completedGoal = goal(
      named: "Completed",
      sortOrder: 4,
      progress: .outcomeCompleted,
    )
    let fixture = try StoreFixture()
    let store = GoalStore(
      goals: [pendingGoal, completedGoal],
      persistence: fixture.persistence,
    )
    let updatedGoal = Goal(
      id: pendingGoal.id,
      name: pendingGoal.name,
      description: pendingGoal.description,
      dueDate: pendingGoal.dueDate,
      createdAt: pendingGoal.createdAt,
      sortOrder: pendingGoal.sortOrder,
      progress: .outcomeCompleted,
    )

    let didUpdate = store.updateGoal(updatedGoal)

    let movedGoal = try #require(store.goals.first { $0.id == pendingGoal.id })
    #expect(didUpdate)
    #expect(movedGoal.isCompleted)
    #expect(movedGoal.sortOrder == 5)
  }

  @Test
  func `Convenience update changes editable fields`() throws {
    let originalGoal = goal(named: "Original")
    let fixture = try StoreFixture()
    let store = GoalStore(goals: [originalGoal], persistence: fixture.persistence)

    let didUpdate = store.updateGoal(
      id: originalGoal.id,
      name: "Edited",
      description: "Details",
      dueDate: date(6),
      progress: .measurable(currentValue: 2, targetValue: 5, step: 1),
    )

    let editedGoal = try #require(store.goals.first)
    #expect(didUpdate)
    #expect(editedGoal.name == "Edited")
    #expect(editedGoal.description == "Details")
    #expect(editedGoal.dueDate == date(6))
    #expect(editedGoal.progress.fractionCompleted == 0.4)
  }

  @Test
  func `Toggle completion updates state and assigns new section sort order`() throws {
    let pendingGoal = goal(named: "Pending", sortOrder: 0)
    let completedGoal = goal(
      named: "Completed",
      sortOrder: 3,
      progress: .outcomeCompleted,
    )
    let fixture = try StoreFixture()
    let store = GoalStore(
      goals: [pendingGoal, completedGoal],
      persistence: fixture.persistence,
    )

    let didToggle = store.toggleCompletion(id: pendingGoal.id)

    let toggledGoal = try #require(store.goals.first { $0.id == pendingGoal.id })
    #expect(didToggle)
    #expect(toggledGoal.isCompleted)
    #expect(toggledGoal.sortOrder == 4)
  }

  @Test
  func `Complete goal increments and decrements progress`() throws {
    let progressGoal = goal(
      named: "Progress",
      progress: .measurable(currentValue: 1, targetValue: 3, step: 1),
    )
    let fixture = try StoreFixture()
    let store = GoalStore(goals: [progressGoal], persistence: fixture.persistence)

    let didIncrement = store.incrementProgress(id: progressGoal.id)
    let didDecrement = store.decrementProgress(id: progressGoal.id)
    let didComplete = store.completeGoal(id: progressGoal.id)

    let updatedGoal = try #require(store.goals.first)
    #expect(didIncrement)
    #expect(didDecrement)
    #expect(didComplete)
    #expect(updatedGoal.isCompleted)
    #expect(updatedGoal.progress.fractionCompleted == 1)
  }

  @Test
  func `Pending and completed goals are filtered and sorted`() {
    let goals = [
      goal(named: "Pending B", sortOrder: 2),
      goal(named: "Completed B", sortOrder: 2, progress: .outcomeCompleted),
      goal(named: "Pending A", sortOrder: 1),
      goal(named: "Completed A", sortOrder: 1, progress: .outcomeCompleted),
    ]
    let store = GoalStore(goals: goals)

    #expect(store.pendingGoals(sortedBy: .manual).map(\.name) == ["Pending A", "Pending B"])
    #expect(store.completedGoals(sortedBy: .manual).map(\.name) == ["Completed A", "Completed B"])
  }

  @Test
  func `Move pending goals updates only pending sort orders and saves`() throws {
    let completedGoal = goal(
      named: "Completed",
      sortOrder: 0,
      progress: .outcomeCompleted,
    )
    let goals = [
      goal(named: "First", sortOrder: 0),
      completedGoal,
      goal(named: "Second", sortOrder: 1),
      goal(named: "Third", sortOrder: 2),
    ]
    let fixture = try StoreFixture()
    let store = GoalStore(goals: goals, persistence: fixture.persistence)

    store.movePendingGoals(from: IndexSet(integer: 0), to: 3)

    #expect(store.pendingGoals(sortedBy: .manual).map(\.name) == ["Second", "Third", "First"])
    #expect(store.completedGoals(sortedBy: .manual).map(\.name) == ["Completed"])
    #expect(try fixture.savedGoals().isEmpty == false)
  }

  @Test
  func `Move completed goals updates only completed sort orders and saves`() throws {
    let goals = [
      goal(named: "Pending", sortOrder: 0),
      goal(named: "Completed First", sortOrder: 0, progress: .outcomeCompleted),
      goal(named: "Completed Second", sortOrder: 1, progress: .outcomeCompleted),
      goal(named: "Completed Third", sortOrder: 2, progress: .outcomeCompleted),
    ]
    let fixture = try StoreFixture()
    let store = GoalStore(goals: goals, persistence: fixture.persistence)

    store.moveCompletedGoals(from: IndexSet(integer: 0), to: 3)

    #expect(store.pendingGoals(sortedBy: .manual).map(\.name) == ["Pending"])
    #expect(
      store.completedGoals(sortedBy: .manual).map(\.name) == [
        "Completed Second", "Completed Third", "Completed First",
      ],
    )
    #expect(try fixture.savedGoals().isEmpty == false)
  }

  @Test
  func `Delete goal removes matching goal and saves`() throws {
    let removedGoal = goal(named: "Remove")
    let remainingGoal = goal(named: "Keep")
    let fixture = try StoreFixture()
    let store = GoalStore(goals: [removedGoal, remainingGoal], persistence: fixture.persistence)

    store.deleteGoal(id: removedGoal.id)

    #expect(store.goals.map(\.id) == [remainingGoal.id])
    #expect(try fixture.savedGoals().map(\.id) == [remainingGoal.id])
  }

  @MainActor
  private final class StoreFixture {
    let directoryURL: URL
    let fileURL: URL
    let persistence: GoalPersistence

    init(persistedGoals: [Goal] = []) throws {
      directoryURL = FileManager.default.temporaryDirectory
        .appending(
          path: UUID().uuidString,
          directoryHint: .isDirectory,
        )
      fileURL = directoryURL.appending(path: "goals.json")
      persistence = GoalPersistence(fileURL: fileURL)
      try persistence.saveGoals(persistedGoals)
    }

    deinit {
      try? FileManager.default.removeItem(at: directoryURL)
    }

    func savedGoals() throws -> [Goal] {
      try persistence.loadGoals()
    }
  }

  private func goal(
    named name: String,
    description: String? = nil,
    dueDate: Date? = nil,
    createdAt: Date = Date(timeIntervalSinceReferenceDate: 0),
    sortOrder: Int = 0,
    progress: GoalProgress = .outcomePending,
  ) -> Goal {
    Goal(
      id: UUID(),
      name: name,
      description: description,
      dueDate: dueDate,
      createdAt: createdAt,
      sortOrder: sortOrder,
      progress: progress,
    )
  }

  private func date(_ day: Int) -> Date {
    Date(timeIntervalSinceReferenceDate: TimeInterval(day * 86400))
  }
}
