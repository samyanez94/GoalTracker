//
//  TargetDateSummaryButton.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct TargetDateSummaryButton: View {
	let hasTargetDate: Bool
	let targetDate: Date
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			Label {
				VStack(alignment: .leading, spacing: 2) {
					Text("Target Date")
					if hasTargetDate {
						Text(GoalTargetDateFormatter.string(from: targetDate))
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
				}
			} icon: {
				Image(systemName: "calendar")
					.foregroundStyle(.secondary)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			.contentShape(.rect)
		}
		.buttonStyle(.plain)
	}
}
