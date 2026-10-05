//
//  GoalStatus.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/27/26.
//

import Foundation

/// The user-facing completion state derived from a goal's progress.
nonisolated enum GoalStatus {
	case pending
	case inProgress
	case completed

	var title: LocalizedStringResource {
		switch self {
		case .pending:
			.goalStatusPending
		case .inProgress:
			.goalStatusInProgress
		case .completed:
			.goalStatusCompleted
		}
	}

	var iconSystemName: String {
		switch self {
		case .pending, .inProgress:
			"circle"
		case .completed:
			"checkmark.circle.fill"
		}
	}
}
