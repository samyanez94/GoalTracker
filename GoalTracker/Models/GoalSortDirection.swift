//
//  GoalSortDirection.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/16/26.
//

import Foundation

enum GoalSortDirection: String, CaseIterable, Identifiable {
	case ascending
	case descending

	var id: Self {
		self
	}

	var title: LocalizedStringResource {
		switch self {
		case .ascending:
			.goalSortDirectionAscending
		case .descending:
			.goalSortDirectionDescending
		}
	}
}
