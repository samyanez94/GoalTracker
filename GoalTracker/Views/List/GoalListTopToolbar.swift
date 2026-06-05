//
//  GoalListTopToolbar.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/16/26.
//

import SwiftUI

struct GoalListTopToolbar: ToolbarContent {
	@Binding var sortMode: GoalSortMode
	@Binding var sortDirection: GoalSortDirection
	@Binding var isShowingCompletedGoals: Bool

	let isEditing: Bool
	let isEditModeEnabled: Bool
	let enterEditMode: () -> Void
	let exitEditMode: () -> Void

	var body: some ToolbarContent {
		ToolbarItem(placement: .topBarTrailing) {
			if isEditing {
				Button("Done", systemImage: "checkmark", action: exitEditMode)
			} else {
				Menu {
					Button(action: enterEditMode) {
						Label("Select Goals", systemImage: "checkmark.circle")
					}
					.disabled(!isEditModeEnabled)
					Menu {
						Picker("Sort", selection: $sortMode) {
							ForEach(GoalSortMode.allCases) { sortMode in
								Text(sortMode.title)
									.tag(sortMode)
							}
						}
						Picker("Direction", selection: $sortDirection) {
							ForEach(GoalSortDirection.allCases) { direction in
								Text(direction.title)
									.tag(direction)
							}
						}
					} label: {
						Label("Sort By", systemImage: "arrow.up.arrow.down")
					}
					Button {
						isShowingCompletedGoals.toggle()
					} label: {
						Label(
							isShowingCompletedGoals ? "Hide Completed" : "Show Completed",
							systemImage: isShowingCompletedGoals ? "eye.slash" : "eye",
						)
					}
				} label: {
					Label("List Options", systemImage: "ellipsis")
				}
			}
		}
	}
}
