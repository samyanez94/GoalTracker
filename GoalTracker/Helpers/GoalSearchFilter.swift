//
//  GoalSearchFilter.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/16/26.
//

import Foundation

struct GoalSearchFilter {
    func filtered(
        _ goals: [Goal],
        searchText: String,
    ) -> [Goal] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearchText.isEmpty else {
            return goals
        }
        return goals.filter { goal in
            goal.name.localizedStandardContains(trimmedSearchText)
        }
    }
}
