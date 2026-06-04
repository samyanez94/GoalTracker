//
//  GoalProgressEventSortOrder.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/4/26.
//

// MARK: - GoalProgressEventSortOrder

enum GoalProgressEventSortOrder: CaseIterable, Identifiable {
	case newestFirst
	case oldestFirst

	var id: Self {
		self
	}

	var title: String {
		switch self {
		case .newestFirst:
			"Newest First"
		case .oldestFirst:
			"Oldest First"
		}
	}
}
