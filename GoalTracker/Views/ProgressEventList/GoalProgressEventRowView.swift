//
//  GoalProgressEventRowView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/3/26.
//

import SwiftUI

// MARK: - GoalProgressEventRowView

struct GoalProgressEventRowView: View {
	let event: GoalProgressEvent
	let unit: GoalProgressUnit?

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			Text(GoalProgressEventFormatter.title(for: event, unit: unit))
			Text(GoalProgressEventFormatter.subtitle(for: event))
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
	}
}

// MARK: - Previews

#Preview("Increased") {
	List {
		GoalProgressEventRowView(
			event: GoalProgressEvent(delta: 5, timestamp: Date()),
			unit: .kilometers,
		)
	}
}

#Preview("Decreased") {
	List {
		GoalProgressEventRowView(
			event: GoalProgressEvent(delta: -10, timestamp: Date()),
			unit: .dollars,
		)
	}
}
