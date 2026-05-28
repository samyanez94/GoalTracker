//
//  GoalStatusTests.swift
//  GoalTrackerTests
//
//  Created by Codex on 5/27/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalStatusTests {
    @Test
    func `Goal status is pending when progress is zero`() {
        let goal = makeGoal(progress: .outcomePending)

        #expect(goal.status == .pending)
        #expect(goal.status.displayString == "Pending")
        #expect(goal.status.iconSystemName == "circle")
    }

    @Test
    func `Goal status is in progress when progress is above zero and incomplete`() {
        let goal = makeGoal(progress: .measurable(currentValue: 2, targetValue: 5))

        #expect(goal.status == .inProgress)
        #expect(goal.status.displayString == "In Progress")
        #expect(goal.status.iconSystemName == "circle")
    }

    @Test
    func `Goal status is completed when progress reaches target`() {
        let goal = makeGoal(progress: .outcomeCompleted)

        #expect(goal.status == .completed)
        #expect(goal.status.displayString == "Completed")
        #expect(goal.status.iconSystemName == "checkmark.circle.fill")
    }

    private func makeGoal(progress: GoalProgress) -> Goal {
        Goal(
            name: "Test Goal",
            details: nil,
            createdAt: Date(),
            progress: progress,
        )
    }
}
