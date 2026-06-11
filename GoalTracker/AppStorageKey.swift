//
//  AppStorageKey.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

/// UserDefaults keys used with SwiftUI's `@AppStorage`.
enum AppStorageKey {
	/// Stores the selected goal list sort mode.
	static let goalSortMode = "goalSortMode"

	/// Stores whether the goal list sorts ascending or descending.
	static let goalSortDirection = "goalSortDirection"

	/// Stores whether completed goals are shown in the goal list.
	static let isShowingCompletedGoals = "isShowingCompletedGoals"

	/// Stores whether the pending goals section is expanded.
	static let isPendingSectionExpanded = "isPendingSectionExpanded"

	/// Stores whether the completed goals section is expanded.
	static let isCompletedSectionExpanded = "isCompletedSectionExpanded"
}
