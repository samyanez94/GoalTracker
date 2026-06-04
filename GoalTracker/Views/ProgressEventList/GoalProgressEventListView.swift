//
//  GoalProgressEventListView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/3/26.
//

import SwiftData
import SwiftUI

// MARK: - GoalProgressEventListView

struct GoalProgressEventListView: View {
	@Environment(\.modelContext) private var modelContext

	let goal: Goal

	@State private var sortOrder = GoalProgressEventSortOrder.newestFirst

	@State private var deletionFailure: GoalProgressEventDeletionFailure?

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
						ForEach(section.events) { event in
							GoalProgressEventRowView(
								event: event,
								unit: progress?.unit,
							)
							.swipeActions {
								Button(role: .destructive) {
									deleteEvent(id: event.id)
								} label: {
									Label("Delete", systemImage: "trash")
								}
							}
						}
					}
				}
			}
		}
		.navigationTitle("Progress")
		.navigationBarTitleDisplayMode(.large)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Menu {
					Picker("Sort", selection: $sortOrder) {
						ForEach(GoalProgressEventSortOrder.allCases) { sortOrder in
							Text(sortOrder.title)
								.tag(sortOrder)
						}
					}
				} label: {
					Label("Sort", systemImage: "arrow.up.arrow.down")
				}
				.disabled(events.isEmpty)
			}
		}
		.alert(item: $deletionFailure) { failure in
			Alert(
				title: Text(failure.title),
				message: Text(failure.message),
				dismissButton: .default(Text("OK")),
			)
		}
	}

	private var progress: MeasurableProgress? {
		guard case .measurable(let progress) = goal.progress else {
			return nil
		}
		return progress
	}

	private var events: [GoalProgressEvent] {
		progress?.events ?? []
	}

	private var eventSections: [GoalProgressEventSection] {
		GoalProgressEventGrouper.sections(
			for: events,
			sortOrder: sortOrder,
		)
	}

	private var goalManager: GoalManager {
		GoalManager(modelContext: modelContext)
	}

	private func deleteEvent(id: GoalProgressEvent.ID) {
		do {
			let didDelete = try withAnimation {
				try goalManager.deleteProgressEvent(id: id, from: goal)
			}
			if !didDelete {
				deletionFailure = .blocked
			}
		} catch {
			deletionFailure = .saveFailed
		}
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
