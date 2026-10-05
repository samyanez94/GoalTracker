//
//  GoalListSectionsView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 10/3/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import SwiftUI

/// The rows shared by normal navigation and bulk edit selection.
struct GoalListSectionsView: View {

	let pendingGoals: [Goal]

	let completedGoals: [Goal]

	let isShowingCompletedGoals: Bool

	@Binding var isPendingSectionExpanded: Bool

	@Binding var isCompletedSectionExpanded: Bool

	var body: some View {
		if isShowingCompletedGoals {
			if !pendingGoals.isEmpty {
				Section(
					String(localized: .goalListSectionPending),
					isExpanded: $isPendingSectionExpanded
				) {
					ForEach(pendingGoals) { goal in
						GoalRowView(goal: goal)
					}
				}
			}
			if !completedGoals.isEmpty {
				Section(
					String(localized: .goalListSectionCompleted),
					isExpanded: $isCompletedSectionExpanded
				) {
					ForEach(completedGoals) { goal in
						GoalRowView(goal: goal)
					}
				}
			}
		} else {
			ForEach(pendingGoals) { goal in
				GoalRowView(goal: goal)
			}
		}
	}
}
