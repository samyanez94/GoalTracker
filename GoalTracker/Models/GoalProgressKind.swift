//
//  GoalProgressKind.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation

/// Describes whether progress is a simple outcome or a measurable target.
nonisolated enum GoalProgressKind: String, Codable {
    case outcome
    case measurable
}
