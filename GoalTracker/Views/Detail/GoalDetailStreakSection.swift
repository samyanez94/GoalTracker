//
//  GoalDetailStreakSection.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/28/26.
//

import SwiftUI

// MARK: - GoalDetailStreakSection

struct GoalDetailStreakSection: View {
	let goal: Goal

	var body: some View {
		if let streakDetails {
			VStack(alignment: .leading, spacing: 8) {
				Text(.detailStreak)
					.font(.headline)
					.foregroundStyle(.secondary)
					.accessibilityAddTraits(.isHeader)
				HStack {
					Image(systemName: streakDetails.iconSystemName)
						.imageScale(.large)
						.foregroundStyle(streakDetails.iconForegroundStyle)
						.contentTransition(.symbolEffect(.replace))
						.accessibilityHidden(true)
					Text(.detailCurrentStreak)
					Spacer(minLength: 8)
					Text(streakDetails.title)
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
				.accessibilityLabel(Text(.detailCurrentStreak))
				.accessibilityValue(streakDetails.title)
			}
		}
	}

	private var streakDetails: StreakDetails? {
		guard let recurrence = goal.recurrence,
			let streak = goal.currentStreak()
		else {
			return nil
		}
		return StreakDetails(
			title: recurrence.cadence.streakValueTitle(for: streak),
			iconSystemName: streak > 0 ? "flame.circle.fill" : "circle",
			iconForegroundStyle: streak > 0 ? AnyShapeStyle(.red) : AnyShapeStyle(.tertiary)
		)
	}

	private struct StreakDetails {
		var title: String
		var iconSystemName: String
		var iconForegroundStyle: AnyShapeStyle
	}
}

// MARK: - Previews

#Preview("Recurring") {
	GoalDetailStreakSection(
		goal: Goal(
			name: "Run",
			details: nil,
			createdAt: Date(),
			progress: .outcome(OutcomeProgress()),
			recurrence: GoalRecurrence(cadence: .daily),
		)
	)
	.padding()
	.background(Color(.systemGroupedBackground))
}
