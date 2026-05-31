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
		direction: GoalSortDirection = .descending,
	) -> [Goal] {
		goals.sorted { lhs, rhs in
			let comparison =
				switch sortMode {
				case .targetDate:
					compareByTargetDate(lhs, rhs, direction: direction)
				case .creationDate:
					compareByCreationDate(lhs, rhs, direction: direction)
				case .name:
					compareByName(lhs, rhs, direction: direction)
				}
			return comparison == .orderedAscending
		}
	}

	private func compareByTargetDate(
		_ lhs: Goal,
		_ rhs: Goal,
		direction: GoalSortDirection,
	) -> ComparisonResult {
		switch (lhs.targetDate, rhs.targetDate) {
		case (let lhsTargetDate?, let rhsTargetDate?):
			if lhsTargetDate != rhsTargetDate {
				return compare(
					lhsTargetDate,
					rhsTargetDate,
					direction: direction,
				)
			}
			return compareByCreationDate(lhs, rhs, direction: .descending)
		case (_?, nil):
			return .orderedAscending
		case (nil, _?):
			return .orderedDescending
		case (nil, nil):
			return compareByCreationDate(lhs, rhs, direction: .descending)
		}
	}

	private func compareByCreationDate(
		_ lhs: Goal,
		_ rhs: Goal,
		direction: GoalSortDirection,
	) -> ComparisonResult {
		if lhs.createdAt != rhs.createdAt {
			return compare(
				lhs.createdAt,
				rhs.createdAt,
				direction: direction,
			)
		}
		return lhs.id.uuidString.localizedStandardCompare(rhs.id.uuidString)
	}

	private func compareByName(
		_ lhs: Goal,
		_ rhs: Goal,
		direction: GoalSortDirection,
	) -> ComparisonResult {
		let comparison = lhs.name.localizedStandardCompare(rhs.name)
		if comparison != .orderedSame {
			return ordered(comparison, direction: direction)
		}
		return compareByCreationDate(lhs, rhs, direction: .descending)
	}

	private func compare<T: Comparable>(
		_ lhs: T,
		_ rhs: T,
		direction: GoalSortDirection,
	) -> ComparisonResult {
		if lhs == rhs {
			return .orderedSame
		}
		if lhs < rhs {
			return ordered(.orderedAscending, direction: direction)
		}
		return ordered(.orderedDescending, direction: direction)
	}

	private func ordered(
		_ result: ComparisonResult,
		direction: GoalSortDirection,
	) -> ComparisonResult {
		switch direction {
		case .ascending:
			result
		case .descending:
			switch result {
			case .orderedAscending:
				.orderedDescending
			case .orderedSame:
				.orderedSame
			case .orderedDescending:
				.orderedAscending
			}
		}
	}
}
