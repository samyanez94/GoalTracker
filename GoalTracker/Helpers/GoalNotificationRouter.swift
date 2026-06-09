//
//  GoalNotificationRouter.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/4/26.
//

import Foundation
import Observation
import UserNotifications

// MARK: - GoalNotificationRouter

/// Routes notification responses into SwiftUI navigation state.
@MainActor
@Observable
final class GoalNotificationRouter: NSObject {
	var pendingGoalId: UUID?

	func navigate(to goalId: UUID) {
		pendingGoalId = goalId
	}
}

// MARK: UNUserNotificationCenterDelegate

extension GoalNotificationRouter: UNUserNotificationCenterDelegate {
	nonisolated func userNotificationCenter(
		_ center: UNUserNotificationCenter,
		didReceive response: UNNotificationResponse,
		withCompletionHandler completionHandler: @escaping @Sendable () -> Void
	) {
		let goalId = GoalNotificationPayload.goalId(
			from: response.notification.request.content.userInfo
		)
		if let goalId {
			Task { @MainActor in
				self.navigate(to: goalId)
				completionHandler()
			}
		} else {
			completionHandler()
		}
	}
}
