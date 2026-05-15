//
//  GoalProgressEntry.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import Foundation
import SwiftData

extension GoalTrackerSchemaV1 {
    /// A dated change to a measurable goal's progress.
    ///
    /// Entries form a history ledger for future charts and calendars. The current
    /// progress summary remains stored on `Goal.progress`.
    @Model
    final class GoalProgressEntry {
        /// A stable app-level identifier for this entry.
        var id: UUID = UUID()
        /// The date when the progress change happened.
        var date: Date = Date()
        /// The signed change in progress value, such as `2` or `-1`.
        var amount: Double = 0
        /// The goal this progress entry belongs to.
        ///
        /// This relationship is optional so the model remains compatible with
        /// CloudKit-backed SwiftData.
        var goal: GoalTrackerSchemaV1.Goal?

        init(
            id: UUID = UUID(),
            date: Date = Date(),
            amount: Double,
            goal: GoalTrackerSchemaV1.Goal? = nil,
        ) {
            self.id = id
            self.date = date
            self.amount = amount
            self.goal = goal
        }
    }
}

typealias GoalProgressEntry = GoalTrackerSchemaV1.GoalProgressEntry
