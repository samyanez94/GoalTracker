/// A skipped reminder is expected; denied permission needs user action.
enum GoalReminderSchedulingOutcome: Equatable {
	case scheduled
	case notNeeded
	case permissionDenied
}
