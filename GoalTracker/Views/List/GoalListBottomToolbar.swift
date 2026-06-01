//
//  GoalListBottomToolbar.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/16/26.
//

import SwiftUI

struct GoalListBottomToolbar: ToolbarContent {
	let isSelectingGoals: Bool
	let selectedGoalCount: Int
	let onAddGoal: () -> Void
	let deleteSelectedGoals: () -> Void

	var body: some ToolbarContent {
		if isSelectingGoals {
			ToolbarItem(placement: .bottomBar) {
				Button(
					selectedGoalCount == 1 ? "Delete Goal" : "Delete Goals",
					systemImage: "trash",
					role: .destructive,
					action: deleteSelectedGoals,
				)
				.disabled(selectedGoalCount == 0)
			}
		} else {
			DefaultToolbarItem(kind: .search, placement: .bottomBar)
			ToolbarSpacer(.flexible, placement: .bottomBar)
			ToolbarItem(placement: .bottomBar) {
				Button("Add Goal", systemImage: "plus", action: onAddGoal)
					.buttonStyle(.glassProminent)
			}
		}
	}
}
