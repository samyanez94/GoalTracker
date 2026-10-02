import Foundation

enum GoalReminderFeedbackContext {
	case goalSaved
	case progressSaved
	case permissionCheck

	var failureMessage: LocalizedStringResource {
		switch self {
		case .goalSaved: .reminderFeedbackGoalSavedFailure
		case .progressSaved: .reminderFeedbackProgressSavedFailure
		case .permissionCheck: .reminderFeedbackSchedulingFailure
		}
	}

	var permissionMessage: LocalizedStringResource {
		switch self {
		case .goalSaved: .reminderFeedbackGoalSavedPermission
		case .progressSaved: .reminderFeedbackProgressSavedPermission
		case .permissionCheck: .reminderFeedbackPermissionRequired
		}
	}
}
