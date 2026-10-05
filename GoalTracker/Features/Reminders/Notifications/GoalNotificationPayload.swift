//
//  GoalNotificationPayload.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/4/26.
//

import Foundation

// MARK: - GoalNotificationPayload

/// Shared keys and parsing for GoalTracker local notification payloads.
enum GoalNotificationPayload {
	nonisolated static let goalIdUserInfoKey = "goalId"

	nonisolated static func goalId(from userInfo: [AnyHashable: Any]) -> UUID? {
		guard let rawGoalId = userInfo[goalIdUserInfoKey] as? String else {
			return nil
		}
		return UUID(uuidString: rawGoalId)
	}
}
