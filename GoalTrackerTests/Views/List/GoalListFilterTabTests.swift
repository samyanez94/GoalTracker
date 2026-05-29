//
//  GoalListFilterTabTests.swift
//  GoalTrackerTests
//
//  Created by Codex on 5/28/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalListFilterTabTests {
    @Test
    func `All tab returns every goal`() {
        let goals = [
            goal(named: "One-time goal"),
            goal(named: "Recurring goal", recurrence: GoalRecurrence(cadence: .daily)),
        ]

        let filteredGoals = GoalListFilterTab.all.filteredGoals(from: goals)

        #expect(filteredGoals.map(\.name) == ["One-time goal", "Recurring goal"])
    }

    @Test
    func `Recurring tab returns only recurring goals`() {
        let goals = [
            goal(named: "One-time goal"),
            goal(named: "Daily goal", recurrence: GoalRecurrence(cadence: .daily)),
            goal(named: "Weekly goal", recurrence: GoalRecurrence(cadence: .weekly)),
        ]

        let filteredGoals = GoalListFilterTab.recurring.filteredGoals(from: goals)

        #expect(filteredGoals.map(\.name) == ["Daily goal", "Weekly goal"])
    }

    private func goal(
        named name: String,
        recurrence: GoalRecurrence? = nil,
    ) -> Goal {
        Goal(
            name: name,
            details: nil,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            progress: .outcomePending,
            recurrence: recurrence,
        )
    }
}
