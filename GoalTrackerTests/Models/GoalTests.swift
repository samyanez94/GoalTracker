//
//  GoalTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/9/26.
//

import Foundation
import Testing

@testable import GoalTracker

// MARK: - GoalTests

@MainActor
@Suite
struct GoalTests {

  @Test
  func `Goal isCompleted delegates to progress`() {
    #expect(makeGoal(progress: .outcomePending).isCompleted == false)
    #expect(makeGoal(progress: .outcomeCompleted).isCompleted == true)
  }

  @Test
  func `Goal complete delegates to progress and updates state`() {
    var goal = makeGoal(progress: .outcomePending)

    let didChange = goal.complete()

    #expect(didChange)
    #expect(goal.isCompleted)
  }

  @Test
  func `Goal markPending delegates to progress and updates state`() {
    var goal = makeGoal(progress: .outcomeCompleted)

    let didChange = goal.markPending()

    #expect(didChange)
    #expect(goal.isCompleted == false)
  }

  @Test
  func `Goal toggleCompletion delegates to progress and updates state`() {
    var goal = makeGoal(progress: .outcomePending)

    let firstToggleChanged = goal.toggleCompletion()
    let secondToggleChanged = goal.toggleCompletion()

    #expect(firstToggleChanged)
    #expect(secondToggleChanged)
    #expect(goal.isCompleted == false)
  }

  @Test
  func `Goal progress changes delegate to progress and update state`() {
    var goal = makeGoal(
      progress: .measurable(currentValue: 4, targetValue: 10, step: 2),
    )

    let incrementChanged = goal.incrementProgress()
    let decrementChanged = goal.decrementProgress()

    #expect(incrementChanged)
    #expect(decrementChanged)
    #expect(goal.progress.fractionCompleted == 0.4)
  }

  @Test
  func `Valid progress values decode successfully`() throws {
    let progress = try decodeProgress(
      """
      {
          "kind": "measurable",
          "currentValue": 4,
          "targetValue": 10,
          "step": 2
      }
      """,
    )

    #expect(progress.kind == .measurable)
    #expect(progress.currentValue == 4)
    #expect(progress.targetValue == 10)
    #expect(progress.step == 2)
  }

  @Test
  func `Invalid progress values throw a data corrupted error`() {
    do {
      _ = try decodeProgress(
        """
        {
            "kind": "measurable",
            "currentValue": 11,
            "targetValue": 10,
            "step": 1
        }
        """,
      )
      Issue.record("Expected invalid progress values to throw.")
    } catch DecodingError.dataCorrupted {
      // Expected.
    } catch {
      Issue.record("Expected dataCorrupted, got \(error).")
    }
  }

  @Test
  func `Missing step decodes with default of one`() throws {
    let progress = try decodeProgress(
      """
      {
          "kind": "measurable",
          "currentValue": 4,
          "targetValue": 10
      }
      """,
    )

    #expect(progress.step == 1)
  }

  private func makeGoal(progress: GoalProgress) -> Goal {
    Goal(
      name: "Test Goal",
      description: nil,
      createdAt: Date(timeIntervalSinceReferenceDate: 0),
      progress: progress,
    )
  }

  private func decodeProgress(_ json: String) throws -> GoalProgress {
    let data = try #require(json.data(using: .utf8))
    return try JSONDecoder().decode(GoalProgress.self, from: data)
  }
}
