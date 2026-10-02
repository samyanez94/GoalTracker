import Foundation

@testable import GoalTracker

@MainActor
final class ReminderSchedulingStub: GoalReminderScheduling {
	var outcome: GoalReminderSchedulingOutcome = .scheduled
	var error: (any Error)?
	var states: [GoalReminderSyncState] = []
	var canceledGoalIds: [UUID] = []
	var beforeSync: (() async -> Void)?

	func syncReminder(
		for state: GoalReminderSyncState,
		requestsAuthorization: Bool,
	) async throws -> GoalReminderSchedulingOutcome {
		states.append(state)
		await beforeSync?()
		if let error { throw error }
		return outcome
	}

	func cancelReminders(for goalIds: [UUID]) {
		canceledGoalIds.append(contentsOf: goalIds)
	}
}
