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
            case .manual:
                sortByManualOrder(lhs, rhs)
            case .dueDate:
                sortByDueDate(lhs, rhs)
            case .creationDate:
                sortByCreationDate(lhs, rhs)
            case .name:
                sortByName(lhs, rhs)
            }
        }
    }

    func nextSortOrder(
        in goals: [Goal],
        isCompleted: Bool,
    ) -> Int {
        let sectionSortOrders = goals
            .filter { $0.isCompleted == isCompleted }
            .map(\.sortOrder)
        return (sectionSortOrders.max() ?? -1) + 1
    }

    func reorderedGoals(
        _ goals: [Goal],
        from source: IndexSet,
        to destination: Int,
        sortedBy sortMode: GoalSortMode,
    ) -> [Goal] {
        var goals = sorted(goals, by: sortMode)
        goals.moveElements(from: source, to: destination)
        return goals
    }

    private func sortByManualOrder(_ lhs: Goal, _ rhs: Goal) -> Bool {
        if lhs.sortOrder != rhs.sortOrder {
            return lhs.sortOrder < rhs.sortOrder
        }
        return lhs.createdAt < rhs.createdAt
    }

    private func sortByDueDate(_ lhs: Goal, _ rhs: Goal) -> Bool {
        switch (lhs.dueDate, rhs.dueDate) {
        case let (lhsDueDate?, rhsDueDate?):
            if lhsDueDate != rhsDueDate {
                return lhsDueDate < rhsDueDate
            }
            return sortByManualOrder(lhs, rhs)
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return sortByManualOrder(lhs, rhs)
        }
    }

    private func sortByCreationDate(_ lhs: Goal, _ rhs: Goal) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }
        return sortByManualOrder(lhs, rhs)
    }

    private func sortByName(_ lhs: Goal, _ rhs: Goal) -> Bool {
        let comparison = lhs.name.localizedStandardCompare(rhs.name)
        if comparison != .orderedSame {
            return comparison == .orderedAscending
        }
        return sortByManualOrder(lhs, rhs)
    }
}

private extension [Goal] {
    mutating func moveElements(from source: IndexSet, to destination: Int) {
        let movingGoals = source.map { self[$0] }
        for index in source.sorted(by: >) {
            remove(at: index)
        }
        let removedBeforeDestination = source.count(where: { $0 < destination })
        let insertionIndex = Swift.max(0, Swift.min(destination - removedBeforeDestination, count))
        insert(contentsOf: movingGoals, at: insertionIndex)
    }
}
