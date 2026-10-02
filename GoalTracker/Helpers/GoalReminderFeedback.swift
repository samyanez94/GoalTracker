import Foundation
import OSLog
import Observation
import SwiftData

/// Reports post-save reminder problems without changing persistence success.
@MainActor
@Observable
final class GoalReminderFeedback {
	private(set) var issue: GoalReminderIssue?
	private(set) var isRetrying = false

	private static let logger = Logger(subsystem: "com.samuel.Moku", category: "Reminders")

	func clearIssue(for goalId: UUID) {
		if issue?.goalId == goalId { issue = nil }
	}

	func sync(
		state: GoalReminderSyncState,
		context: GoalReminderFeedbackContext,
		scheduler: any GoalReminderScheduling,
		requestsAuthorization: Bool,
		modelContext: ModelContext? = nil,
	) async {
		do {
			// A queued post-save task should read the latest goal, not an old snapshot.
			let currentState: GoalReminderSyncState
			if let modelContext {
				guard let goal = try fetchGoal(id: state.goalId, modelContext: modelContext) else {
					scheduler.cancelReminders(for: [state.goalId])
					clearIssue(for: state.goalId)
					return
				}
				currentState = GoalReminderSyncState(goal: goal)
			} else {
				currentState = state
			}
			let nextIssue = try await schedulingIssue(
				state: currentState,
				context: context,
				scheduler: scheduler,
				requestsAuthorization: requestsAuthorization,
			)
			if let modelContext,
				currentState.reminder != nil,
				try cancelIfUnavailable(goalId: state.goalId, modelContext: modelContext, scheduler: scheduler)
			{
				return
			}
			if nextIssue != nil || issue?.goalId == state.goalId {
				issue = nextIssue
			}
		} catch is CancellationError {
			// Cancellation is not a notification-center failure.
		} catch {
			report(error)
			issue = GoalReminderIssue(
				goalId: state.goalId,
				goalName: state.goalName,
				context: context,
				error: error,
			)
		}
	}

	/// Disable the selected goal's reminder without clearing feedback on a save failure.
	func disableReminder(for goalId: UUID, modelContext: ModelContext) throws {
		guard issue?.goalId == goalId, !isRetrying else { return }
		guard let goal = try fetchGoal(id: goalId, modelContext: modelContext) else {
			clearIssue(for: goalId)
			return
		}
		try GoalManager(modelContext: modelContext, reminderFeedback: self).disableReminder(goal)
	}

	/// Resolve the latest saved goal; retries never repeat a save or progress change.
	func retry(
		modelContext: ModelContext,
		scheduler: any GoalReminderScheduling = GoalNotificationScheduler(),
	) async {
		guard let originalIssue = issue, !isRetrying else { return }
		isRetrying = true
		defer { isRetrying = false }

		do {
			let goalId = originalIssue.goalId
			if try cancelIfUnavailable(goalId: goalId, modelContext: modelContext, scheduler: scheduler) {
				return
			}
			guard let goal = try fetchGoal(id: goalId, modelContext: modelContext) else { return }
			let nextIssue = try await schedulingIssue(
				state: GoalReminderSyncState(goal: goal),
				context: originalIssue.context,
				scheduler: scheduler,
				requestsAuthorization: true,
			)
			if try cancelIfUnavailable(goalId: goalId, modelContext: modelContext, scheduler: scheduler) {
				return
			}
			// An unrelated failure may have arrived while the retry was suspended.
			if issue?.id == originalIssue.id { issue = nextIssue }
		} catch is CancellationError {
			return
		} catch {
			report(error)
			if issue?.id == originalIssue.id {
				issue = GoalReminderIssue(
					goalId: originalIssue.goalId,
					goalName: originalIssue.goalName,
					context: originalIssue.context,
					error: error,
				)
			}
		}
	}

	private func fetchGoal(id: UUID, modelContext: ModelContext) throws -> Goal? {
		let descriptor = FetchDescriptor<Goal>(predicate: #Predicate { $0.id == id })
		return try modelContext.fetch(descriptor).first
	}

	/// A goal may have been disabled or deleted while notification work was suspended.
	private func cancelIfUnavailable(
		goalId: UUID,
		modelContext: ModelContext,
		scheduler: any GoalReminderScheduling,
	) throws -> Bool {
		guard try fetchGoal(id: goalId, modelContext: modelContext)?.reminder == nil else { return false }
		scheduler.cancelReminders(for: [goalId])
		clearIssue(for: goalId)
		return true
	}

	private func schedulingIssue(
		state: GoalReminderSyncState,
		context: GoalReminderFeedbackContext,
		scheduler: any GoalReminderScheduling,
		requestsAuthorization: Bool,
	) async throws -> GoalReminderIssue? {
		do {
			let outcome = try await scheduler.syncReminder(
				for: state,
				requestsAuthorization: requestsAuthorization,
			)
			guard outcome == .permissionDenied else { return nil }
			return GoalReminderIssue(
				goalId: state.goalId,
				goalName: state.goalName,
				context: context,
				error: nil,
			)
		} catch is CancellationError {
			throw CancellationError()
		} catch {
			report(error)
			return GoalReminderIssue(
				goalId: state.goalId,
				goalName: state.goalName,
				context: context,
				error: error,
			)
		}
	}

	private func report(_ error: any Error) {
		Self.logger.error("Reminder scheduling failed: \(String(reflecting: error), privacy: .private)")
	}
}
