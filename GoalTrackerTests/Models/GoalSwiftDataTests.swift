//
//  GoalSwiftDataTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation
import SwiftData
import Testing

@testable import GoalTracker

@MainActor
struct GoalSwiftDataTests {
  @Test
  func `Model container stores goals and cascades progress entries`() throws {
    let container = try ModelContainer(
      for: Goal.self,
      GoalProgressEntry.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true),
    )
    let context = container.mainContext
    let goal = Goal(
      name: "Walk daily",
      details: nil,
      createdAt: Date(timeIntervalSinceReferenceDate: 0),
      progress: .measurable(currentValue: 1, targetValue: 10),
    )
    let entry = GoalProgressEntry(
      date: Date(timeIntervalSinceReferenceDate: 0),
      amount: 1,
      goal: goal,
    )

    context.insert(goal)
    context.insert(entry)
    try context.save()

    #expect(try context.fetch(FetchDescriptor<Goal>()).count == 1)
    #expect(try context.fetch(FetchDescriptor<GoalProgressEntry>()).count == 1)

    context.delete(goal)
    try context.save()

    #expect(try context.fetch(FetchDescriptor<Goal>()).isEmpty)
    #expect(try context.fetch(FetchDescriptor<GoalProgressEntry>()).isEmpty)
  }
}
