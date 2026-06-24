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
	let onDelete: ((IndexSet) -> Void)?

	@Binding var isExpanded: Bool

	init(
		title: String,
		goals: [Goal],
		isExpanded: Binding<Bool>,
		onDelete: ((IndexSet) -> Void)? = nil,
	) {
		self.title = title
		self.goals = goals
		self.onDelete = onDelete
		_isExpanded = isExpanded
	}

	init(
		title: LocalizedStringResource,
		goals: [Goal],
		isExpanded: Binding<Bool>,
		onDelete: ((IndexSet) -> Void)? = nil,
	) {
		self.init(
			title: String(localized: title),
			goals: goals,
			isExpanded: isExpanded,
			onDelete: onDelete,
		)
	}

	var body: some View {
		if !goals.isEmpty {
			Section(isExpanded: $isExpanded) {
				ForEach(goals) { goal in
					GoalRowView(goal: goal)
				}
				.onDelete(perform: onDelete)
			} header: {
				CollapsibleSectionHeader(
					title: title,
					isExpanded: $isExpanded,
				)
			}
		}
	}
}
