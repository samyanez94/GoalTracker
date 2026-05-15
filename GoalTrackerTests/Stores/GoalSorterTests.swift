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
    func `Due date sorting puts dated goals before undated goals`() {
        let goals = [
            goal(named: "Undated", dueDate: nil),
            goal(named: "Later", dueDate: date(3)),
            goal(named: "Sooner", dueDate: date(2)),
        ]

        let sortedGoals = sorter.sorted(goals, by: .dueDate)

        #expect(sortedGoals.map(\.name) == ["Sooner", "Later", "Undated"])
    }

    @Test
    func `Creation date sorting puts newest goals first`() {
        let goals = [
            goal(named: "Oldest", createdAt: date(1)),
            goal(named: "Newest", createdAt: date(3)),
            goal(named: "Middle", createdAt: date(2)),
        ]

        let sortedGoals = sorter.sorted(goals, by: .creationDate)

        #expect(sortedGoals.map(\.name) == ["Newest", "Middle", "Oldest"])
    }

    @Test
    func `Name sorting uses localized standard order`() {
        let goals = [
            goal(named: "Goal 10"),
            goal(named: "Goal 2"),
            goal(named: "Goal 1"),
        ]

        let sortedGoals = sorter.sorted(goals, by: .name)

        #expect(sortedGoals.map(\.name) == ["Goal 1", "Goal 2", "Goal 10"])
    }

    private func goal(
        named name: String,
        dueDate: Date? = nil,
        createdAt: Date = Date(timeIntervalSinceReferenceDate: 0),
        progress: GoalProgress = .outcomePending,
    ) -> Goal {
        Goal(
            id: UUID(),
            name: name,
            details: nil,
            dueDate: dueDate,
            createdAt: createdAt,
            progress: progress,
        )
    }

    private func date(_ day: Int) -> Date {
        Date(timeIntervalSinceReferenceDate: TimeInterval(day * 86400))
    }
}
