//
//  GoalRecurrence.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation

nonisolated struct GoalRecurrence: Codable, Hashable {
    var cadence: Cadence
}

extension GoalRecurrence {
    nonisolated enum Cadence: String, Codable, Hashable {
        case daily
        case weekly
        case monthly
    }
}
