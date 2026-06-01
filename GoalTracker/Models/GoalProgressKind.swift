//
//  GoalProgressKind.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation

/// Describes whether progress is a simple outcome or a measurable target.
nonisolated enum GoalProgressKind: String, Codable {
	/// A binary goal that is either pending or complete.
	case outcome
	/// A goal that advances toward a numeric target value.
	case measurable
}
