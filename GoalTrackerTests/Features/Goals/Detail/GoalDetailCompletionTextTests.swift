//
//  GoalDetailCompletionTextTests.swift
//  GoalTrackerTests
//
//  Created by Codex on 6/11/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalDetailCompletionTextTests {
	@Test
	func `One-time outcome detail completion footer includes completion date`() throws {
		let goal = makeGoal(
			progress: .outcome(
				OutcomeProgress.completed(
					timestamp: ModelTestSupport.date(year: 2026, month: 6, day: 11),
				)
			),
		)

		let text = try #require(
			goal.detailCompletionFooterText(
				at: ModelTestSupport.date(year: 2026, month: 6, day: 12),
				calendar: ModelTestSupport.calendar,
				locale: Locale(identifier: "en_US"),
			)
		)

		#expect(String(localized: text) == "Completed on Jun 11, 2026")
	}

	@Test
	func `One-time measurable detail completion footer uses event that reaches target`() throws {
		let goal = makeGoal(
			progress: .measurable(
				MeasurableProgress(
					events: [
						GoalProgressEvent(
							delta: 4,
							timestamp: ModelTestSupport.date(year: 2026, month: 6, day: 9),
						),
						GoalProgressEvent(
							delta: 6,
							timestamp: ModelTestSupport.date(year: 2026, month: 6, day: 11),
						)
					],
					targetValue: 10,
				)
			),
		)

		let text = try #require(
			goal.detailCompletionFooterText(
				at: ModelTestSupport.date(year: 2026, month: 6, day: 12),
				calendar: ModelTestSupport.calendar,
				locale: Locale(identifier: "en_US"),
			)
		)

		#expect(String(localized: text) == "Completed on Jun 11, 2026")
	}

	@Test
	func `Daily recurring detail completion footer says reset tomorrow`() throws {
		let goal = makeGoal(
			progress: .outcome(
				OutcomeProgress.completed(
					timestamp: ModelTestSupport.date(year: 2026, month: 6, day: 11),
				)
			),
			recurrence: GoalRecurrence(cadence: .daily),
		)

		let text = try #require(
			goal.detailCompletionFooterText(
				at: ModelTestSupport.date(year: 2026, month: 6, day: 11, hour: 12),
				calendar: ModelTestSupport.calendar,
			)
		)

		#expect(String(localized: text) == "Completed today. Resets tomorrow")
	}

	@Test
	func `Weekly recurring detail completion footer says days until reset`() throws {
		let goal = makeGoal(
			progress: .outcome(
				OutcomeProgress.completed(
					timestamp: ModelTestSupport.date(year: 2026, month: 6, day: 12),
				)
			),
			recurrence: GoalRecurrence(cadence: .weekly),
		)

		let text = try #require(
			goal.detailCompletionFooterText(
				at: ModelTestSupport.date(year: 2026, month: 6, day: 12, hour: 12),
				calendar: ModelTestSupport.calendar,
			)
		)

		#expect(String(localized: text) == "Completed this week. Resets in 3 days")
	}

	@Test
	func `Incomplete goal has no detail completion footer`() {
		let goal = makeGoal(progress: .outcome(OutcomeProgress()))

		#expect(
			goal.detailCompletionFooterText(
				at: ModelTestSupport.date(year: 2026, month: 6, day: 11),
				calendar: ModelTestSupport.calendar,
			) == nil
		)
	}
}
