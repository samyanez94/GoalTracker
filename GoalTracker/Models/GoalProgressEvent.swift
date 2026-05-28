//
//  GoalProgressEvent.swift
//  GoalTracker
//
//  Created by Codex on 5/28/26.
//

import Foundation

/// A timestamped change to a goal's progress value.
nonisolated struct GoalProgressEvent: Codable, Equatable {
    /// The amount added to or removed from the goal's progress.
    var delta: Double
    /// The time this progress change happened.
    var timestamp: Date
}
