//
//  GoalStatusTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/27/26.
//

import Testing

@testable import GoalTracker

@MainActor
struct GoalStatusTests {
	@Test(
		arguments: [
			(GoalStatus.pending, "Pending"),
			(.inProgress, "In Progress"),
			(.completed, "Completed")
		],
	)
	func `Display strings describe each status`(
		status: GoalStatus,
		expectedDisplayString: String,
	) {
		#expect(status.displayString == expectedDisplayString)
	}

	@Test(
		arguments: [
			(GoalStatus.pending, "circle"),
			(.inProgress, "circle"),
			(.completed, "checkmark.circle.fill")
		],
	)
	func `Icon names describe each status`(
		status: GoalStatus,
		expectedIconSystemName: String,
	) {
		#expect(status.iconSystemName == expectedIconSystemName)
	}
}
