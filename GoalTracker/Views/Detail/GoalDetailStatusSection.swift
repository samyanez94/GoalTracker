//
//  GoalDetailStatusSection.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/24/26.
//

import SwiftUI

// MARK: - GoalDetailStatusSection

struct GoalDetailStatusSection: View {
	let goal: Goal

	var body: some View {
        let status = goal.status()
		VStack(alignment: .leading, spacing: 8) {
			GoalDetailSectionHeader(title: .commonStatus)
			GoalDetailCard {
				HStack {
					Image(systemName: status.iconSystemName)
						.imageScale(.large)
						.foregroundStyle(goal.isCompleted() ? AnyShapeStyle(.accent) : AnyShapeStyle(.tertiary))
						.contentTransition(.symbolEffect(.replace))
						.accessibilityHidden(true)
					Text(.commonStatus)
					Spacer(minLength: 8)
					Text(status.title)
						.foregroundStyle(.secondary)
						.multilineTextAlignment(.trailing)
				}
			}
			.accessibilityElement(children: .ignore)
			.accessibilityLabel(Text(.commonStatus))
			.accessibilityValue(status.title)
			if let footerText {
				Text(footerText)
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
		}
	}

	private var footerText: LocalizedStringResource? {
		goal.detailCompletionFooterText()
	}
}

// MARK: - Previews

#Preview("Pending") {
	GoalDetailStatusSection(
		goal: Goal(
			name: "Travel to Japan",
			details: "Plan and take the trip.",
			createdAt: Date(),
			progress: .outcome(OutcomeProgress()),
		)
	)
	.padding()
	.background(Color(.systemGroupedBackground))
}

#Preview("Completed") {
	GoalDetailStatusSection(
		goal: Goal(
			name: "Travel to Japan",
			details: "Plan and take the trip.",
			createdAt: Date(),
			progress: .outcome(OutcomeProgress.completed(timestamp: Date())),
		)
	)
	.padding()
	.background(Color(.systemGroupedBackground))
}

#Preview("In Progress") {
	GoalDetailStatusSection(
		goal: Goal(
			name: "Run a 5K",
			details: "Build up endurance with three runs per week.",
			createdAt: Date(),
			progress: .measurable(currentValue: 2, targetValue: 5),
		)
	)
	.padding()
	.background(Color(.systemGroupedBackground))
}
