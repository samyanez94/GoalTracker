//
//  GoalReminderUpdating.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 10/5/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import Foundation

/// The goals feature's interface for updating reminders after successful persistence.
///
/// `GoalService` reports saved changes through this protocol without depending on
/// notification APIs, scheduling tasks, or reminder feedback state. Callers must
/// invoke these methods only after the goal changes have been saved successfully.
///
/// Implementations own scheduling, cancellation, and any resulting feedback.
/// These methods return without waiting for asynchronous scheduling to finish; reminder
/// failures must not turn a successful goal save into a persistence failure.
@MainActor
protocol GoalReminderUpdating {
	/// Requests a reminder update for a goal whose changes were successfully saved.
	///
	/// - Parameters:
	///   - goal: The saved goal that changed.
	///   - reason: The saved action, used to choose scheduling and permission behavior.
	func goalDidChange(_ goal: Goal, reason: GoalReminderChange)

	/// Requests cancellation and feedback cleanup after goal deletion was saved.
	///
	/// IDs remain usable after the corresponding persisted models have been deleted.
	/// - Parameter goalIDs: The IDs of the successfully deleted goals.
	func goalsWereDeleted(_ goalIDs: Set<UUID>)
}
