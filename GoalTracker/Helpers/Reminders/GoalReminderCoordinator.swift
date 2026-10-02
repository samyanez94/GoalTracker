import Foundation
import OSLog
import Observation
import SwiftData
import UserNotifications

/// Coordinates local reminder scheduling, reconciliation, and issue state by goal.
@MainActor
@Observable
final class GoalReminderCoordinator {
	private(set) var issues: [UUID: GoalReminderIssue] = [:]
	private var retryingGoalIds: Set<UUID> = []

	@ObservationIgnored private let permissionDefaults: UserDefaults
	@ObservationIgnored private var permissionCheckId: UUID?
	@ObservationIgnored private let operationQueue = GoalReminderOperationQueue()

	init(permissionDefaults: UserDefaults = .standard) {
		self.permissionDefaults = permissionDefaults
	}

	func issue(for goalId: UUID) -> GoalReminderIssue? { issues[goalId] }

	func isRetrying(for goalId: UUID) -> Bool { retryingGoalIds.contains(goalId) }

	private static let logger = Logger(subsystem: "com.samuel.Moku", category: "Reminders")

	func clearIssue(for goalId: UUID) {
		issues[goalId] = nil
	}

	func sync(
		state: GoalReminderSyncState,
		context: GoalReminderFeedbackContext,
		scheduler: any GoalReminderScheduling,
		requestsAuthorization: Bool,
		modelContext: ModelContext? = nil,
	) async {
		await operationQueue.acquire(for: state.goalId)
		defer { operationQueue.release(for: state.goalId) }
		guard !Task.isCancelled else { return }
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
			guard !Task.isCancelled else { return }
			issues[state.goalId] = nextIssue
		} catch is CancellationError {
			// Cancellation is not a notification-center failure.
		} catch {
			report(error)
			issues[state.goalId] = GoalReminderIssue(
				goalId: state.goalId,
				goalName: state.goalName,
				context: context,
				error: error,
			)
		}
	}

	/// Disable the selected goal's reminder without clearing feedback on a save failure.
	func disableReminder(for goalId: UUID, modelContext: ModelContext) throws {
		guard issues[goalId] != nil, !isRetrying(for: goalId) else { return }
		guard let goal = try fetchGoal(id: goalId, modelContext: modelContext) else {
			clearIssue(for: goalId)
			return
		}
		try GoalManager(modelContext: modelContext, reminderCoordinator: self).disableReminder(goal)
	}

	/// Resolve the latest saved goal; retries never repeat a save or progress change.
	func retry(
		for goalId: UUID,
		modelContext: ModelContext,
		scheduler: any GoalReminderScheduling = GoalNotificationScheduler(),
		requestsAuthorization: Bool = true,
	) async {
		guard issues[goalId] != nil, !isRetrying(for: goalId) else { return }
		retryingGoalIds.insert(goalId)
		defer { retryingGoalIds.remove(goalId) }
		await operationQueue.acquire(for: goalId)
		defer { operationQueue.release(for: goalId) }
		guard !Task.isCancelled, let originalIssue = issues[goalId] else { return }

		do {
			if try cancelIfUnavailable(goalId: goalId, modelContext: modelContext, scheduler: scheduler) {
				return
			}
			guard let goal = try fetchGoal(id: goalId, modelContext: modelContext) else { return }
			let nextIssue = try await schedulingIssue(
				state: GoalReminderSyncState(goal: goal),
				context: originalIssue.context,
				scheduler: scheduler,
				requestsAuthorization: requestsAuthorization,
			)
			if try cancelIfUnavailable(goalId: goalId, modelContext: modelContext, scheduler: scheduler) {
				return
			}
			// An unrelated failure may have arrived while the retry was suspended.
			if issues[goalId]?.id == originalIssue.id { issues[goalId] = nextIssue }
		} catch is CancellationError {
			return
		} catch {
			report(error)
			if issues[goalId]?.id == originalIssue.id {
				issues[goalId] = GoalReminderIssue(
					goalId: originalIssue.goalId,
					goalName: originalIssue.goalName,
					context: originalIssue.context,
					error: error,
				)
			}
		}
	}

	/// Repair this device's pending reminders without requesting notification permission.
	func reconcileReminders(
		modelContext: ModelContext,
		notificationCenter: any GoalNotificationCenterClient = UNUserNotificationCenter.current(),
		calendar: Calendar = .current,
		now: @escaping () -> Date = Date.init,
	) async {
		await refreshPermissions(
			modelContext: modelContext,
			notificationCenter: notificationCenter,
			scheduler: GoalNotificationScheduler(notificationCenter: notificationCenter, calendar: calendar, now: now),
			calendar: calendar,
			now: now,
			reconcilesPendingRequests: true
		)
	}

	/// Check existing permission without prompting; optionally repair pending requests.
	/// Remember denial so permission restored while the app was closed can recover reminders.
	func refreshPermissions(
		modelContext: ModelContext,
		notificationCenter: any GoalNotificationCenterClient = UNUserNotificationCenter.current(),
		scheduler: any GoalReminderScheduling = GoalNotificationScheduler(),
		calendar: Calendar = .current,
		now: @escaping () -> Date = Date.init,
		reconcilesPendingRequests: Bool = false,
	) async {
		let checkId = UUID()
		permissionCheckId = checkId
		let pendingRequests = reconcilesPendingRequests ? await notificationCenter.pendingNotificationRequests() : []
		guard permissionCheckId == checkId, !Task.isCancelled else { return }
		let status = await notificationCenter.authorizationStatus()
		guard permissionCheckId == checkId, !Task.isCancelled else { return }

		do {
			let currentDate = now()
			let goals = try modelContext.fetch(FetchDescriptor<Goal>())
			let eligibleGoals = goals.map { GoalReminderSyncState(goal: $0) }
				.filter {
					GoalReminderSchedule.reminder(
						state: $0,
						calendar: calendar,
						currentDate: currentDate,
					) != nil
				}
			let eligibleIds = Set(eligibleGoals.map(\.goalId))
			let removedIds = issues.keys.filter { !eligibleIds.contains($0) }
			for goalId in removedIds { clearIssue(for: goalId) }
			scheduler.cancelReminders(for: removedIds)
			let matcher = GoalNotificationScheduler(notificationCenter: notificationCenter, calendar: calendar, now: now)
			if reconcilesPendingRequests {
				let obsoleteIds = pendingRequests.compactMap { request -> UUID? in
					guard let goalId = matcher.reminderGoalId(for: request.identifier) else { return nil }
					return !eligibleIds.contains(goalId) || status != .authorized ? goalId : nil
				}
				scheduler.cancelReminders(for: obsoleteIds)
			}

			switch status {
			case .denied:
				permissionDefaults.set(true, forKey: AppStorageKey.wereGoalRemindersDenied)
				for goal in eligibleGoals where issues[goal.goalId]?.isPermissionDenied != true {
					issues[goal.goalId] = GoalReminderIssue(
						goalId: goal.goalId,
						goalName: goal.goalName,
						context: .permissionCheck,
						error: nil,
					)
				}
			case .notDetermined:
				// A first launch must not produce a warning or a permission prompt.
				for goal in eligibleGoals where issues[goal.goalId]?.isPermissionDenied == true {
					clearIssue(for: goal.goalId)
				}
				permissionDefaults.set(false, forKey: AppStorageKey.wereGoalRemindersDenied)
			case .authorized:
				let wasDenied = permissionDefaults.bool(forKey: AppStorageKey.wereGoalRemindersDenied)
				for goal in eligibleGoals {
					guard permissionCheckId == checkId, !Task.isCancelled else { return }
					if reconcilesPendingRequests {
						guard !isRetrying(for: goal.goalId) else { continue }
						guard let currentGoal = try fetchGoal(id: goal.goalId, modelContext: modelContext) else {
							scheduler.cancelReminders(for: [goal.goalId])
							clearIssue(for: goal.goalId)
							continue
						}
						let currentState = GoalReminderSyncState(goal: currentGoal)
						let request = pendingRequests.first { $0.identifier == matcher.reminderNotificationIdentifier(for: goal.goalId) }
						if matcher.isReminderCurrent(for: currentState, request: request) {
							clearIssue(for: goal.goalId)
						} else {
							await sync(state: currentState, context: .permissionCheck, scheduler: scheduler, requestsAuthorization: false, modelContext: modelContext)
						}
						continue
					}
					guard wasDenied || issues[goal.goalId]?.isPermissionDenied == true else { continue }
					if issues[goal.goalId] == nil {
						issues[goal.goalId] = GoalReminderIssue(
							goalId: goal.goalId,
							goalName: goal.goalName,
							context: .permissionCheck,
							error: nil,
						)
					}
					await retry(
						for: goal.goalId,
						modelContext: modelContext,
						scheduler: scheduler,
						requestsAuthorization: false,
					)
				}
				guard permissionCheckId == checkId, !Task.isCancelled else { return }
				permissionDefaults.set(false, forKey: AppStorageKey.wereGoalRemindersDenied)
			}
		} catch {
			report(error)
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
