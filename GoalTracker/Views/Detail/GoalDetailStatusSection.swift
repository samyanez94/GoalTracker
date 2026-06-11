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
		VStack(alignment: .leading, spacing: 8) {
			Text(.commonStatus)
				.font(.headline)
				.foregroundStyle(.secondary)
				.accessibilityAddTraits(.isHeader)
			HStack {
				Image(systemName: goal.status().iconSystemName)
					.imageScale(.large)
					.foregroundStyle(goal.isCompleted() ? AnyShapeStyle(.accent) : AnyShapeStyle(.tertiary))
					.contentTransition(.symbolEffect(.replace))
					.accessibilityHidden(true)
				Text(.commonStatus)
				Spacer(minLength: 8)
				Text(goal.status().title)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.trailing)
			}
			.padding(.all, 16)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(
				Color(.secondarySystemGroupedBackground),
				in: .rect(cornerRadius: 24, style: .continuous),
			)
			.accessibilityElement(children: .ignore)
			.accessibilityLabel(Text(.commonStatus))
			.accessibilityValue(goal.status().title)
		}
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
