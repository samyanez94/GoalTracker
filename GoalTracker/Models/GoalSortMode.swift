//
//  GoalSortMode.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/8/26.
//

import Foundation

enum GoalSortMode: String, CaseIterable, Identifiable {
	case targetDate
	case creationDate
	case name

	var id: Self {
		self
	}

	var title: LocalizedStringResource {
		switch self {
		case .targetDate:
			.goalSortModeTargetDate
		case .creationDate:
			.goalSortModeCreationDate
		case .name:
			.goalSortModeName
		}
	}
}
