//
//  GoalSearchFilterTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/16/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalSearchFilterTests {
    private let filter = GoalSearchFilter()

    @Test
    func `Empty search returns all goals`() {
        let goals = [
            goal(named: "Run a 5K"),
            goal(named: "Read books"),
        ]

        let filteredGoals = filter.filtered(
            goals,
            searchText: "   ",
        )

        #expect(filteredGoals.map(\.name) == ["Run a 5K", "Read books"])
    }

    @Test
    func `Search matches goal names`() {
        let goals = [
            goal(named: "Run a 5K"),
            goal(named: "Read books"),
            goal(named: "Travel to Japan"),
        ]

        let filteredGoals = filter.filtered(
            goals,
            searchText: "run",
        )

        #expect(filteredGoals.map(\.name) == ["Run a 5K"])
    }

    @Test
    func `Search uses localized standard matching`() {
        let goals = [
            goal(named: "Goal 10"),
            goal(named: "Goal 2"),
        ]

        let filteredGoals = filter.filtered(
            goals,
            searchText: "goal 2",
        )

        #expect(filteredGoals.map(\.name) == ["Goal 2"])
    }

    @Test
    func `Search does not match details`() {
        let goals = [
            goal(
                named: "Move daily",
                details: "Run after work.",
            ),
            goal(named: "Read books"),
        ]

        let filteredGoals = filter.filtered(
            goals,
            searchText: "run",
        )

        #expect(filteredGoals.isEmpty)
    }

    @Test
    func `Completion visibility can be applied after search`() {
        let goals = [
            goal(named: "Run a 5K", progress: .outcomePending),
            goal(named: "Run a marathon", progress: .outcomeCompleted),
        ]

        let visibleSearchResults = filter.filtered(
            goals,
            searchText: "run",
        )
        .filter { !$0.isCompleted }

        #expect(visibleSearchResults.map(\.name) == ["Run a 5K"])
    }

    private func goal(
        named name: String,
        details: String? = nil,
        progress: GoalProgress = .outcomePending,
    ) -> Goal {
        Goal(
            name: name,
            details: details,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            progress: progress,
        )
    }
}
