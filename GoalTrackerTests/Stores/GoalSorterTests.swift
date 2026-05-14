//
//  GoalSorterTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/12/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalSorterTests {
  private let sorter = GoalSorter()

  @Test
  func `Manual sorting orders goals by sort order`() {
    let goals = [
      goal(named: "Second", createdAt: date(1), sortOrder: 2),
      goal(named: "First", createdAt: date(2), sortOrder: 1),
      goal(named: "Third", createdAt: date(3), sortOrder: 3),
    ]

    let sortedGoals = sorter.sorted(goals, by: .manual)

    #expect(sortedGoals.map(\.name) == ["First", "Second", "Third"])
  }

  @Test
  func `Manual sorting falls back to creation date`() {
    let goals = [
      goal(named: "Newer", createdAt: date(2), sortOrder: 1),
      goal(named: "Older", createdAt: date(1), sortOrder: 1),
    ]

    let sortedGoals = sorter.sorted(goals, by: .manual)

    #expect(sortedGoals.map(\.name) == ["Older", "Newer"])
  }

  @Test
  func `Due date sorting puts dated goals before undated goals`() {
    let goals = [
      goal(named: "Undated", dueDate: nil, sortOrder: 1),
      goal(named: "Later", dueDate: date(3), sortOrder: 2),
      goal(named: "Sooner", dueDate: date(2), sortOrder: 3),
    ]

    let sortedGoals = sorter.sorted(goals, by: .dueDate)

    #expect(sortedGoals.map(\.name) == ["Sooner", "Later", "Undated"])
  }

  @Test
  func `Creation date sorting puts newest goals first`() {
    let goals = [
      goal(named: "Oldest", createdAt: date(1), sortOrder: 1),
      goal(named: "Newest", createdAt: date(3), sortOrder: 2),
      goal(named: "Middle", createdAt: date(2), sortOrder: 3),
    ]

    let sortedGoals = sorter.sorted(goals, by: .creationDate)

    #expect(sortedGoals.map(\.name) == ["Newest", "Middle", "Oldest"])
  }

  @Test
  func `Name sorting uses localized standard order`() {
    let goals = [
      goal(named: "Goal 10", sortOrder: 1),
      goal(named: "Goal 2", sortOrder: 2),
      goal(named: "Goal 1", sortOrder: 3),
    ]

    let sortedGoals = sorter.sorted(goals, by: .name)

    #expect(sortedGoals.map(\.name) == ["Goal 1", "Goal 2", "Goal 10"])
  }

  @Test
  func `Next sort order only considers goals in the same completion section`() {
    let goals = [
      goal(named: "Pending", sortOrder: 4),
      goal(named: "Completed", sortOrder: 12, progress: .outcomeCompleted),
    ]

    #expect(sorter.nextSortOrder(in: goals, isCompleted: false) == 5)
    #expect(sorter.nextSortOrder(in: goals, isCompleted: true) == 13)
  }

  @Test
  func `Reordered goals move within the selected sort mode`() {
    let goals = [
      goal(named: "Third", sortOrder: 3),
      goal(named: "First", sortOrder: 1),
      goal(named: "Second", sortOrder: 2),
    ]

    let reorderedGoals = sorter.reorderedGoals(
      goals,
      from: IndexSet(integer: 0),
      to: 3,
      sortedBy: .manual,
    )

    #expect(reorderedGoals.map(\.name) == ["Second", "Third", "First"])
  }

  private func goal(
    named name: String,
    dueDate: Date? = nil,
    createdAt: Date = Date(timeIntervalSinceReferenceDate: 0),
    sortOrder: Int = 0,
    progress: GoalProgress = .outcomePending,
  ) -> Goal {
    Goal(
      id: UUID(),
      name: name,
      description: nil,
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
