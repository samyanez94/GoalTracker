import Foundation

/// Transient feedback, separate from the persisted reminder preference.
struct GoalReminderIssue: Identifiable {
	let id = UUID()
	let goalId: UUID
	let goalName: String
	let context: GoalReminderFeedbackContext
	/// Retain the underlying failure for diagnostics, without exposing it to users.
	let error: (any Error)?

	var isPermissionDenied: Bool { error == nil }

	var message: LocalizedStringResource {
		isPermissionDenied ? context.permissionMessage : context.failureMessage
	}
}
