import Foundation

@testable import GoalTracker

@MainActor
final class ReminderSchedulingStub: GoalReminderScheduling {
	var outcome: GoalReminderSchedulingOutcome = .scheduled
	var error: (any Error)?
	var failingGoalIds: Set<UUID> = []
	var authorizationRequests: [Bool] = []
	var states: [GoalReminderSyncState] = []
	var canceledGoalIds: [UUID] = []
	var beforeSync: (() async -> Void)?

	func syncReminder(
		for state: GoalReminderSyncState,
		requestsAuthorization: Bool,
	) async throws -> GoalReminderSchedulingOutcome {
		states.append(state)
		authorizationRequests.append(requestsAuthorization)
		await beforeSync?()
		if let error, failingGoalIds.isEmpty || failingGoalIds.contains(state.goalId) { throw error }
		return outcome
	}

	func cancelReminders(for goalIds: [UUID]) {
		canceledGoalIds.append(contentsOf: goalIds)
	}
}
