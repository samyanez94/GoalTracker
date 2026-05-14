//
//  GoalSortModeTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/12/26.
//

import Testing

@testable import GoalTracker

@MainActor
struct GoalSortModeTests {
  @Test
  func `Titles are human readable`() {
    #expect(GoalSortMode.manual.title == "Manual")
    #expect(GoalSortMode.dueDate.title == "Due Date")
    #expect(GoalSortMode.creationDate.title == "Date Created")
    #expect(GoalSortMode.name.title == "Name")
  }
}
