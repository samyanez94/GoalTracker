//
//  GoalSorter.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/8/26.
//

import Foundation

struct GoalSorter {
    func sorted(
        _ goals: [Goal],
        by sortMode: GoalSortMode,
    ) -> [Goal] {
        goals.sorted { lhs, rhs in
            switch sortMode {
            case .dueDate:
                sortByDueDate(lhs, rhs)
            case .creationDate:
                sortByCreationDate(lhs, rhs)
            case .name:
                sortByName(lhs, rhs)
            }
        }
    }

    private func sortByDueDate(_ lhs: Goal, _ rhs: Goal) -> Bool {
        switch (lhs.dueDate, rhs.dueDate) {
        case (let lhsDueDate?, let rhsDueDate?):
            if lhsDueDate != rhsDueDate {
                return lhsDueDate < rhsDueDate
            }
            return sortByCreationDate(lhs, rhs)
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return sortByCreationDate(lhs, rhs)
        }
    }

    private func sortByCreationDate(_ lhs: Goal, _ rhs: Goal) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    private func sortByName(_ lhs: Goal, _ rhs: Goal) -> Bool {
        let comparison = lhs.name.localizedStandardCompare(rhs.name)
        if comparison != .orderedSame {
            return comparison == .orderedAscending
        }
        return sortByCreationDate(lhs, rhs)
    }
}
