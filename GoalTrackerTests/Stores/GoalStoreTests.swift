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
  func `Initializes with provided goals`() {
    let providedGoal = goal(named: "Provided")

    let store = GoalStore(goals: [providedGoal])

    #expect(store.goals.map(\.name) == ["Provided"])
  }

  @Test
  func `Initializes with empty goals by default`() {
    let store = GoalStore()

    #expect(store.goals.isEmpty)
  }

  @Test
  func `Add goal assigns next sort order for its completion section`() throws {
    let completedGoal = goal(
      named: "Completed",
      sortOrder: 8,
      progress: .outcomeCompleted,
    )
    let pendingGoal = goal(named: "Pending", sortOrder: 2)
    let store = GoalStore(goals: [completedGoal, pendingGoal])

    store.addGoal(goal(named: "New Pending", sortOrder: 99))

    let addedGoal = try #require(store.goals.last)
    #expect(addedGoal.name == "New Pending")
    #expect(addedGoal.sortOrder == 3)
  }

  @Test
  func `Update goal changes existing values`() throws {
    let originalGoal = goal(named: "Original")
    let store = GoalStore(goals: [originalGoal])
    let updatedGoal = Goal(
      id: originalGoal.id,
      name: "Updated",
      details: "Updated description",
      dueDate: date(4),
      createdAt: originalGoal.createdAt,
      sortOrder: originalGoal.sortOrder,
      progress: .outcomePending,
    )

    let didUpdate = store.updateGoal(updatedGoal)

    #expect(didUpdate)
    #expect(store.goals.first?.name == "Updated")
    #expect(store.goals.first?.details == "Updated description")
  }

  @Test
  func `Update goal returns false when id is missing`() {
    let originalGoal = goal(named: "Original")
    let store = GoalStore(goals: [originalGoal])
    let missingGoal = goal(named: "Missing")

    let didUpdate = store.updateGoal(missingGoal)

    #expect(didUpdate == false)
    #expect(store.goals.map(\.id) == [originalGoal.id])
  }

  @Test
  func `Updating completion moves goal to end of new completion section`() throws {
    let pendingGoal = goal(named: "Pending", sortOrder: 1)
    let completedGoal = goal(
      named: "Completed",
      sortOrder: 4,
      progress: .outcomeCompleted,
    )
    let store = GoalStore(goals: [pendingGoal, completedGoal])
    let updatedGoal = Goal(
      id: pendingGoal.id,
      name: pendingGoal.name,
      details: pendingGoal.details,
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
    let store = GoalStore(goals: [originalGoal])

    let didUpdate = store.updateGoal(
      id: originalGoal.id,
      name: "Edited",
      details: "Details",
      dueDate: date(6),
      progress: .measurable(currentValue: 2, targetValue: 5, step: 1),
    )

    let editedGoal = try #require(store.goals.first)
    #expect(didUpdate)
    #expect(editedGoal.name == "Edited")
    #expect(editedGoal.details == "Details")
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
    let store = GoalStore(goals: [pendingGoal, completedGoal])

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
    let store = GoalStore(goals: [progressGoal])

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
  func `Move pending goals updates only pending sort orders`() {
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
    let store = GoalStore(goals: goals)

    store.movePendingGoals(from: IndexSet(integer: 0), to: 3)

    #expect(store.pendingGoals(sortedBy: .manual).map(\.name) == ["Second", "Third", "First"])
    #expect(store.completedGoals(sortedBy: .manual).map(\.name) == ["Completed"])
  }

  @Test
  func `Move completed goals updates only completed sort orders`() {
    let goals = [
      goal(named: "Pending", sortOrder: 0),
      goal(named: "Completed First", sortOrder: 0, progress: .outcomeCompleted),
      goal(named: "Completed Second", sortOrder: 1, progress: .outcomeCompleted),
      goal(named: "Completed Third", sortOrder: 2, progress: .outcomeCompleted),
    ]
    let store = GoalStore(goals: goals)

    store.moveCompletedGoals(from: IndexSet(integer: 0), to: 3)

    #expect(store.pendingGoals(sortedBy: .manual).map(\.name) == ["Pending"])
    #expect(
      store.completedGoals(sortedBy: .manual).map(\.name) == [
        "Completed Second", "Completed Third", "Completed First",
      ],
    )
  }

  @Test
  func `Delete goal removes matching goal`() {
    let removedGoal = goal(named: "Remove")
    let remainingGoal = goal(named: "Keep")
    let store = GoalStore(goals: [removedGoal, remainingGoal])

    store.deleteGoal(id: removedGoal.id)

    #expect(store.goals.map(\.id) == [remainingGoal.id])
  }

  private func goal(
    named name: String,
    details: String? = nil,
    dueDate: Date? = nil,
    createdAt: Date = Date(timeIntervalSinceReferenceDate: 0),
    sortOrder: Int = 0,
    progress: GoalProgress = .outcomePending,
  ) -> Goal {
    Goal(
      id: UUID(),
      name: name,
      details: details,
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
