//
//  GoalProgressEventDeletionFailure.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/4/26.
//

// MARK: - GoalProgressEventDeletionFailure

enum GoalProgressEventDeletionFailure: Identifiable {
	case blocked
	case blockedBatch
	case saveFailed

	var id: Self {
		self
	}

	var title: String {
		switch self {
		case .blocked:
			"Progress Event Not Deleted"
		case .blockedBatch:
			"Progress Events Not Deleted"
		case .saveFailed:
			"Couldn't Delete Progress"
		}
	}

	var message: String {
		switch self {
		case .blocked:
			"Deleting this event would make the remaining progress history invalid."
		case .blockedBatch:
			"Deleting these events would make the remaining progress history invalid."
		case .saveFailed:
			"Your progress change wasn't saved. Please try again."
		}
	}
}
