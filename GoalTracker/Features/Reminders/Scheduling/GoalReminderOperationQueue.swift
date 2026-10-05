import Foundation

/// Keeps notification writes for the same goal in order across suspended operations.
@MainActor
final class GoalReminderOperationQueue {
	private var activeGoalIds: Set<UUID> = []
	private var waiters: [UUID: [CheckedContinuation<Void, Never>]] = [:]

	func acquire(for goalId: UUID) async {
		if activeGoalIds.insert(goalId).inserted { return }
		await withCheckedContinuation { continuation in
			waiters[goalId, default: []].append(continuation)
		}
	}

	func release(for goalId: UUID) {
		guard var queued = waiters[goalId], !queued.isEmpty else {
			activeGoalIds.remove(goalId)
			return
		}
		let next = queued.removeFirst()
		waiters[goalId] = queued.isEmpty ? nil : queued
		next.resume()
	}
}
