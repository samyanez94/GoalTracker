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
				Button(.commonDone, systemImage: "checkmark", action: exitEditMode)
			} else {
				Menu {
					Button(action: enterEditMode) {
						Label(.goalListSelectGoals, systemImage: "checkmark.circle")
					}
					.disabled(!isEditModeEnabled)
					Menu {
						Picker(.commonSort, selection: $sortMode) {
							ForEach(GoalSortMode.allCases) { sortMode in
								Text(sortMode.title)
									.tag(sortMode)
							}
						}
						Picker(.commonDirection, selection: $sortDirection) {
							ForEach(GoalSortDirection.allCases) { direction in
								Text(direction.title)
									.tag(direction)
							}
						}
					} label: {
						Label(.toolbarSortBy, systemImage: "arrow.up.arrow.down")
					}
					Button {
						isShowingCompletedGoals.toggle()
					} label: {
						Label(
							completedGoalsVisibilityTitle,
							systemImage: isShowingCompletedGoals ? "eye.slash" : "eye",
						)
					}
				} label: {
					Label(.toolbarListOptions, systemImage: "ellipsis")
				}
			}
		}
	}

	private var completedGoalsVisibilityTitle: LocalizedStringResource {
		isShowingCompletedGoals ? .goalListHideCompleted : .goalListShowCompleted
	}
}
