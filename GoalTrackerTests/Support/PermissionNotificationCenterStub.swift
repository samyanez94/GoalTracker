import UserNotifications

@testable import GoalTracker

@MainActor
final class PermissionNotificationCenterStub: GoalNotificationCenterClient {
	var status: GoalNotificationAuthorizationStatus
	private(set) var authorizationRequestCount = 0
	private(set) var addedRequestCount = 0
	var pendingRequests: [UNNotificationRequest] = []
	var addError: (any Error)?
	private(set) var removedIdentifiers: [String] = []
	var beforePendingRequests: (() async -> Void)?
	var beforeAdd: (() async -> Void)?

	init(status: GoalNotificationAuthorizationStatus) {
		self.status = status
	}

	func authorizationStatus() async -> GoalNotificationAuthorizationStatus { status }

	func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
		authorizationRequestCount += 1
		return false
	}

	func pendingNotificationRequests() async -> [UNNotificationRequest] {
		await beforePendingRequests?()
		return pendingRequests
	}

	func add(_ request: UNNotificationRequest) async throws {
		await beforeAdd?()
		if let addError { throw addError }
		addedRequestCount += 1
		pendingRequests.removeAll { $0.identifier == request.identifier }
		pendingRequests.append(request)
	}

	func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
		removedIdentifiers.append(contentsOf: identifiers)
		pendingRequests.removeAll { identifiers.contains($0.identifier) }
	}
}
