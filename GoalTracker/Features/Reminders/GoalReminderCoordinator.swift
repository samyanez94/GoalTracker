import Foundation
import OSLog
import Observation
import SwiftData
import UserNotifications

/// Owns this device's reminder lifecycle and observable recovery feedback.
///
/// Implements `GoalReminderUpdating` by starting scheduling after successful goal
/// saves and cancelling pending reminders after disabling or deletion. It also
/// retries failed operations and reconciles pending requests with current goal
/// settings and notification permission. Notification request construction and
/// scheduling are delegated to the configured scheduler.
///
/// `GoalNavigationView` owns and shares one coordinator. Its context, notification
/// center, scheduler, calendar, and clock are configured at initialization and
/// reused across operations. Scheduling and retries are serialized per goal and
/// re-read current goal settings around suspended work to handle disabling or deletion.
///
/// The coordinator reads goal data but never saves or mutates it. Reminder failures
/// appear in transient `issues` state; they do not undo a successful goal save.
@MainActor
@Observable
final class GoalReminderCoordinator: GoalReminderUpdating {
	/// Current reminder failures by goal ID, observed by the list and detail UI.
	private(set) var issues: [UUID: GoalReminderIssue] = [:]

	private var retryingGoalIds: Set<UUID> = []

	@ObservationIgnored private let permissionDefaults: UserDefaults

	@ObservationIgnored private var permissionCheckId: UUID?

	@ObservationIgnored private let operationQueue = GoalReminderOperationQueue()

	private let modelContext: ModelContext
	private let notificationCenter: any GoalNotificationCenterClient
	private let scheduler: any GoalReminderScheduling
	private let matcher: GoalNotificationScheduler
	private let calendar: Calendar
	private let now: () -> Date

	/// Configures the shared dependencies used throughout the reminder lifecycle.
	///
	/// Use the same model context as the goal service. When `scheduler` is omitted,
	/// a notification scheduler uses the supplied notification center, calendar,
	/// and clock. `permissionDefaults` remembers device-local permission denial
	/// across launches; it does not store goal reminder preferences.
	init(
		modelContext: ModelContext,
		notificationCenter: any GoalNotificationCenterClient = UNUserNotificationCenter.current(),
		scheduler: (any GoalReminderScheduling)? = nil,
		calendar: Calendar = .current,
		now: @escaping () -> Date = Date.init,
		permissionDefaults: UserDefaults = .standard
	) {
		self.modelContext = modelContext
		self.notificationCenter = notificationCenter
		self.calendar = calendar
		self.now = now
		self.permissionDefaults = permissionDefaults
		let notificationScheduler = GoalNotificationScheduler(notificationCenter: notificationCenter, calendar: calendar, now: now)
		self.matcher = notificationScheduler
		self.scheduler = scheduler ?? notificationScheduler
	}

	/// Starts reminder work after a successful goal save, independently of the originating view.
	///
	/// Details saves may request notification permission; progress saves never prompt.
	/// Disabling requests cancellation and clears feedback immediately. Other changes
	/// schedule asynchronously from the latest goal settings, keeping the model
	/// container alive until the task finishes.
	func goalDidChange(_ goal: Goal, reason: GoalReminderChange) {
		if reason == .reminderDisabled {
			cancelReminders(for: [goal.id])
			return
		}
		let state = GoalReminderSyncState(goal: goal)
		let context: GoalReminderFeedbackContext = reason == .progressSaved ? .progressSaved : .goalSaved
		let container = modelContext.container
		// Finish post-save work even when the originating sheet disappears.
		Task { @MainActor in
			defer { withExtendedLifetime(container) {} }
			await sync(state: state, context: context, requestsAuthorization: reason == .detailsSaved)
		}
	}

	/// Requests cancellation of pending reminders and clears feedback for saved deletions.
	func goalsWereDeleted(_ goalIDs: Set<UUID>) {
		cancelReminders(for: goalIDs)
	}

	private func cancelReminders(for goalIDs: Set<UUID>) {
		scheduler.cancelReminders(for: Array(goalIDs))
		for goalID in goalIDs {
			clearIssue(for: goalID)
		}
	}

	/// Returns the current recoverable reminder issue for a goal, if any.
	func issue(for goalId: UUID) -> GoalReminderIssue? { issues[goalId] }

	/// Indicates whether a retry is queued or running for a goal.
	func isRetrying(for goalId: UUID) -> Bool { retryingGoalIds.contains(goalId) }

	private static let logger = Logger(subsystem: "com.samuel.Moku", category: "Reminders")

	/// Clears transient feedback without changing goal settings or pending requests.
	func clearIssue(for goalId: UUID) {
		issues[goalId] = nil
	}

	/// Serializes one scheduling operation and updates feedback from the latest goal settings.
	///
	/// `state` supplies the goal ID and fallback error metadata; scheduling uses a
	/// fresh fetch from the configured context. Checks after scheduling remove
	/// requests for goals disabled or deleted while the operation was suspended.
	func sync(
		state: GoalReminderSyncState,
		context: GoalReminderFeedbackContext,
		requestsAuthorization: Bool,
	) async {
		await operationQueue.acquire(for: state.goalId)
		defer {
			operationQueue.release(for: state.goalId)
		}
		guard !Task.isCancelled else {
			return
		}
		do {
			// A queued post-save task should read the latest goal, not an old snapshot.
			guard let goal = try fetchGoal(id: state.goalId) else {
				scheduler.cancelReminders(for: [state.goalId])
				clearIssue(for: state.goalId)
				return
			}
			let currentState = GoalReminderSyncState(goal: goal)
			let nextIssue = try await schedulingIssue(
				state: currentState,
				context: context,
				requestsAuthorization: requestsAuthorization,
			)
			if currentState.reminder != nil,
				try cancelIfUnavailable(goalId: state.goalId)
			{
				return
			}
			guard !Task.isCancelled else {
				return
			}
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

	/// Retries an existing issue using current goal settings and the configured scheduler.
	///
	/// Ignores duplicate retries and preserves feedback replaced by another operation.
	/// A retry never repeats a goal save or progress change. Permission may be
	/// requested for a user-initiated retry; automatic recovery passes `false`.
	func retry(
		for goalId: UUID,
		requestsAuthorization: Bool = true,
	) async {
		guard issues[goalId] != nil,
			!isRetrying(for: goalId)
		else {
			return
		}
		retryingGoalIds.insert(goalId)
		defer {
			retryingGoalIds.remove(goalId)
		}
		await operationQueue.acquire(for: goalId)
		defer {
			operationQueue.release(for: goalId)
		}
		guard !Task.isCancelled, let originalIssue = issues[goalId] else {
			return
		}

		do {
			if try cancelIfUnavailable(goalId: goalId) {
				return
			}
			guard let goal = try fetchGoal(id: goalId) else {
				return
			}
			let nextIssue = try await schedulingIssue(
				state: GoalReminderSyncState(goal: goal),
				context: originalIssue.context,
				requestsAuthorization: requestsAuthorization,
			)
			if try cancelIfUnavailable(goalId: goalId) {
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

	/// Repairs this device's pending reminders to match current goal settings.
	///
	/// Called when the app becomes active or relevant goal data changes. Adds or
	/// updates eligible requests and removes obsolete requests without prompting
	/// for notification permission or changing persisted goal preferences.
	func reconcileReminders() async {
		await refreshPermissions(reconcilesPendingRequests: true)
	}

	/// Refreshes permission feedback and optionally reconciles pending requests without prompting.
	///
	/// Remembers permission denial across launches and retries affected goals when
	/// permission is restored. A newer check or cancellation supersedes suspended work.
	/// - Parameter reconcilesPendingRequests: Whether to also repair missing, outdated,
	///   or obsolete notification requests. Ordinary checks only refresh permission
	///   feedback and recover reminders affected by restored permission.
	func refreshPermissions(reconcilesPendingRequests: Bool = false) async {
		let checkId = UUID()
		permissionCheckId = checkId
		let pendingRequests = reconcilesPendingRequests ? await notificationCenter.pendingNotificationRequests() : []
		guard permissionCheckId == checkId,
			!Task.isCancelled
		else {
			return
		}
		let status = await notificationCenter.authorizationStatus()
		guard permissionCheckId == checkId, !Task.isCancelled else {
			return
		}

		do {
			let currentDate = now()
			let goals = try modelContext.fetch(FetchDescriptor<Goal>())
			let eligibleGoals =
				goals.map {
					GoalReminderSyncState(goal: $0)
				}
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
			if reconcilesPendingRequests {
				let obsoleteIds = pendingRequests.compactMap { request -> UUID? in
					guard let goalId = matcher.reminderGoalId(for: request.identifier) else {
						return nil
					}
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
						guard let currentGoal = try fetchGoal(id: goal.goalId) else {
							scheduler.cancelReminders(for: [goal.goalId])
							clearIssue(for: goal.goalId)
							continue
						}
						let currentState = GoalReminderSyncState(goal: currentGoal)
						let request = pendingRequests.first { $0.identifier == matcher.reminderNotificationIdentifier(for: goal.goalId) }
						if matcher.isReminderCurrent(for: currentState, request: request) {
							clearIssue(for: goal.goalId)
						} else {
							await sync(state: currentState, context: .permissionCheck, requestsAuthorization: false)
						}
						continue
					}
					guard wasDenied || issues[goal.goalId]?.isPermissionDenied == true else {
						continue
					}
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

	private func fetchGoal(id: UUID) throws -> Goal? {
		let descriptor = FetchDescriptor<Goal>(predicate: #Predicate { $0.id == id })
		return try modelContext.fetch(descriptor).first
	}

	/// A goal may have been disabled or deleted while notification work was suspended.
	private func cancelIfUnavailable(
		goalId: UUID,
	) throws -> Bool {
		guard try fetchGoal(id: goalId)?.reminder == nil else { return false }
		scheduler.cancelReminders(for: [goalId])
		clearIssue(for: goalId)
		return true
	}

	private func schedulingIssue(
		state: GoalReminderSyncState,
		context: GoalReminderFeedbackContext,
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
