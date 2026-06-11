//
//  GoalSectionView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct GoalSectionView: View {
	let title: String
	let goals: [Goal]

	@Binding var isExpanded: Bool

	init(
		title: String,
		goals: [Goal],
		isExpanded: Binding<Bool>,
	) {
		self.title = title
		self.goals = goals
		_isExpanded = isExpanded
	}

	init(
		title: LocalizedStringResource,
		goals: [Goal],
		isExpanded: Binding<Bool>,
	) {
		self.init(
			title: String(localized: title),
			goals: goals,
			isExpanded: isExpanded,
		)
	}

	var body: some View {
		if !goals.isEmpty {
			Section(isExpanded: $isExpanded) {
				ForEach(goals) { goal in
					GoalRowView(goal: goal)
						.tag(goal.id)
				}
			} header: {
				CollapsibleSectionHeader(
					title: title,
					isExpanded: $isExpanded,
				)
			}
		}
	}
}
