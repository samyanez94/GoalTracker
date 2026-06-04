//
//  GoalProgressEventListView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/3/26.
//

import SwiftUI

// MARK: - GoalProgressEventListView

struct GoalProgressEventListView: View {
	let goal: Goal

	var body: some View {
		Group {
			if events.isEmpty {
				Text("No progress yet")
					.font(.body)
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.background(Color(.systemGroupedBackground))
			} else {
				List(eventSections) { section in
					Section(section.title) {
						ForEach(section.events.enumerated(), id: \.offset) { _, event in
							GoalProgressEventRowView(
								event: event,
								unit: progress?.unit,
							)
						}
					}
				}
			}
		}
		.navigationTitle("Progress")
		.navigationBarTitleDisplayMode(.large)
	}

	private var progress: MeasurableProgress? {
		guard case .measurable(let progress) = goal.progress else {
			return nil
		}
		return progress
	}

	private var events: [GoalProgressEvent] {
		progress?.events.sorted { $0.timestamp > $1.timestamp } ?? []
	}

	private var eventSections: [GoalProgressEventSection] {
		GoalProgressEventGrouper.sections(for: events)
	}
}

// MARK: - Previews

#Preview("Progress Events") {
	NavigationStack {
		GoalProgressEventListView(
			goal: Goal(
				name: "Run a 5K",
				details: "Build up distance each week.",
				createdAt: Date(),
				progress: .measurable(
					MeasurableProgress(
						events: [
							GoalProgressEvent(delta: 2.5, timestamp: Date()),
							GoalProgressEvent(
								delta: -1,
								timestamp: Date().addingTimeInterval(-3_600),
							),
							GoalProgressEvent(
								delta: 1,
								timestamp: Date().addingTimeInterval(-259_200),
							),
							GoalProgressEvent(
								delta: 3,
								timestamp: Date().addingTimeInterval(-31_536_000),
							),
						],
						targetValue: 5,
						unit: .kilometers,
					)
				),
			)
		)
	}
}

#Preview("Empty") {
	NavigationStack {
		GoalProgressEventListView(
			goal: Goal(
				name: "Run a 5K",
				details: "Build up distance each week.",
				createdAt: Date(),
				progress: .measurable(currentValue: 0, targetValue: 5),
			)
		)
	}
}
