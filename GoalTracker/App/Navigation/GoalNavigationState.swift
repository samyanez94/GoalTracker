//
//  GoalNavigationState.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 10/3/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import Foundation
import Observation

/// Keeps sidebar selection independent from screens pushed within the detail column.
@MainActor
@Observable
final class GoalNavigationState {

	/// The ID of the goal displayed at the root of the detail column, or `nil` when none is selected.
	var selectedGoalID: UUID? {
		didSet {
			if selectedGoalID != oldValue {
				detailPath.removeAll()
			}
		}
	}

	/// The destinations pushed above the selected goal in the detail column's navigation stack.
	var detailPath: [GoalNavigationDestination] = []

	/// Bulk editing must not replace the goal displayed in the detail column.
	func updateSidebarSelection(_ goalID: UUID?, isEditing: Bool) {
		guard !isEditing else {
			return
		}
		selectedGoalID = goalID
	}
}
