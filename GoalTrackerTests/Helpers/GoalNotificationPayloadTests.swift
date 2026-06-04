//
//  GoalNotificationPayloadTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 6/4/26.
//

import Foundation
import Testing

@testable import GoalTracker

// MARK: - GoalNotificationPayloadTests

struct GoalNotificationPayloadTests {
	@Test
	func `Goal id parses from notification user info`() {
		let goalId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
		let userInfo: [AnyHashable: Any] = [
			GoalNotificationPayload.goalIdUserInfoKey: goalId.uuidString
		]

		#expect(GoalNotificationPayload.goalId(from: userInfo) == goalId)
	}

	@Test
	func `Goal id is nil when notification user info is missing or invalid`() {
		#expect(GoalNotificationPayload.goalId(from: [:]) == nil)
		#expect(
			GoalNotificationPayload.goalId(
				from: [GoalNotificationPayload.goalIdUserInfoKey: "not-a-uuid"]
			) == nil
		)
	}
}
