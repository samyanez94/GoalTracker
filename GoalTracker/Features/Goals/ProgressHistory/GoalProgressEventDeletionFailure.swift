//
//  GoalProgressEventDeletionFailure.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/4/26.
//

import Foundation

// MARK: - GoalProgressEventDeletionFailure

enum GoalProgressEventDeletionFailure: Identifiable {
	case blocked
	case blockedBatch
	case saveFailed

	var id: Self {
		self
	}

	var title: LocalizedStringResource {
		switch self {
		case .blocked:
			.progressEventDeletionFailureBlockedTitle
		case .blockedBatch:
			.progressEventDeletionFailureBlockedBatchTitle
		case .saveFailed:
			.progressEventDeletionFailureSaveFailedTitle
		}
	}

	var message: LocalizedStringResource {
		switch self {
		case .blocked:
			.progressEventDeletionFailureBlockedMessage
		case .blockedBatch:
			.progressEventDeletionFailureBlockedBatchMessage
		case .saveFailed:
			.progressEventDeletionFailureSaveFailedMessage
		}
	}
}
