//
//  GoalProgressEventSortOrder.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/4/26.
//

import Foundation

// MARK: - GoalProgressEventSortOrder

enum GoalProgressEventSortOrder: CaseIterable, Identifiable {
	case newestFirst
	case oldestFirst

	var id: Self {
		self
	}

	var title: LocalizedStringResource {
		switch self {
		case .newestFirst:
			.progressEventSortOrderNewestFirst
		case .oldestFirst:
			.progressEventSortOrderOldestFirst
		}
	}
}
