//
//  GoalDetailStreakSection.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/28/26.
//

import SwiftUI

struct GoalDetailStreakSection: View {
	let goal: Goal

	var body: some View {
		if let streakDetails {
			VStack(alignment: .leading, spacing: 8) {
				Text("Streak")
					.font(.headline)
					.foregroundStyle(.secondary)
				HStack {
					Image(systemName: streakDetails.iconSystemName)
						.font(.title2)
						.foregroundStyle(streakDetails.iconForegroundStyle)
						.contentTransition(.symbolEffect(.replace))
						.accessibilityHidden(true)
					Text("Current Streak")
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
			iconForegroundStyle: streak > 0 ? Color.red : Color.secondary
		)
	}

	private struct StreakDetails {
		var title: String
		var iconSystemName: String
		var iconForegroundStyle: Color
	}
}

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
