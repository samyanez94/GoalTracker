//
//  GoalStatus.swift
//  GoalTracker
//
//  Created by Codex on 5/27/26.
//

import Foundation

/// The user-facing completion state derived from a goal's progress.
nonisolated enum GoalStatus {
    case pending
    case inProgress
    case completed

    var displayString: String {
        switch self {
        case .pending:
            "Pending"
        case .inProgress:
            "In Progress"
        case .completed:
            "Completed"
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
