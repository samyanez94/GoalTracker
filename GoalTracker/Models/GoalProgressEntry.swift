//
//  GoalProgressEntry.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation
import SwiftData

@Model
final class GoalProgressEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var amount: Double = 0
    var note: String?
    var goal: Goal?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Double,
        note: String? = nil,
        goal: Goal? = nil,
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.note = note
        self.goal = goal
    }
}
