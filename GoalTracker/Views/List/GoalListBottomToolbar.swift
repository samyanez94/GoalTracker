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

	@Binding var isPresentingDeleteConfirmation: Bool

	let deleteSelectedGoals: () -> Void

	var body: some ToolbarContent {
		if isSelectingGoals {
			ToolbarItem(placement: .bottomBar) {
				Button(
					selectedGoalCount == 1 ? "Delete Goal" : "Delete Goals",
					systemImage: "trash",
					role: .destructive,
					action: {
						isPresentingDeleteConfirmation = true
					},
				)
				.disabled(selectedGoalCount == 0)
				.accessibilityLabel(deleteButtonAccessibilityLabel)
				.goalDeleteConfirmationDialog(
					isPresented: $isPresentingDeleteConfirmation,
					goalCount: selectedGoalCount,
					onDelete: deleteSelectedGoals,
				)
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

	private var deleteButtonAccessibilityLabel: String {
		switch selectedGoalCount {
		case 0:
			"Delete selected goals"
		case 1:
			"Delete 1 selected goal"
		default:
			"Delete \(selectedGoalCount) selected goals"
		}
	}
}
