import Foundation

enum GoalReminderFeedbackContext {
	case goalSaved
	case progressSaved

	var failureMessage: LocalizedStringResource {
		switch self {
		case .goalSaved: .reminderFeedbackGoalSavedFailure
		case .progressSaved: .reminderFeedbackProgressSavedFailure
		}
	}

	var permissionMessage: LocalizedStringResource {
		switch self {
		case .goalSaved: .reminderFeedbackGoalSavedPermission
		case .progressSaved: .reminderFeedbackProgressSavedPermission
		}
	}
}
