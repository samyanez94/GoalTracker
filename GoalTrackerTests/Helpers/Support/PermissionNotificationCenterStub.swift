import UserNotifications

@testable import GoalTracker

@MainActor
final class PermissionNotificationCenterStub: GoalNotificationCenterClient {
	var status: GoalNotificationAuthorizationStatus
	private(set) var authorizationRequestCount = 0
	private(set) var addedRequestCount = 0

	init(status: GoalNotificationAuthorizationStatus) {
		self.status = status
	}

	func authorizationStatus() async -> GoalNotificationAuthorizationStatus { status }

	func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
		authorizationRequestCount += 1
		return false
	}

	func add(_ request: UNNotificationRequest) async throws {
		addedRequestCount += 1
	}

	func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}
