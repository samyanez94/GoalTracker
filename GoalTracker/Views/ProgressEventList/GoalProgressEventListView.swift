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

	@State private var editMode = EditMode.inactive

	@State private var sortOrder = GoalProgressEventSortOrder.newestFirst

	@State private var selectedEventIds = Set<GoalProgressEvent.ID>()

	@State private var isPresentingDeleteConfirmation = false

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
				List(selection: $selectedEventIds) {
					ForEach(eventSections) { section in
						Section(section.title) {
							ForEach(section.events) { event in
								GoalProgressEventRowView(
									event: event,
									unit: progress?.unit,
								)
								.tag(event.id)
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
		}
		.navigationTitle("History")
		.navigationBarTitleDisplayMode(.large)
		.environment(\.editMode, $editMode)
		.toolbar {
			if editMode.isEditing {
				ToolbarItem(placement: .topBarLeading) {
					Button(selectAllButtonTitle, action: toggleSelectAllEvents)
						.disabled(eventIds.isEmpty)
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done", systemImage: "checkmark", action: exitEditMode)
				}
				ToolbarItem(placement: .bottomBar) {
					Button(
                        selectedEventIds.count == 1 ? "Delete Event" : "Delete Events",
						systemImage: "trash",
						role: .destructive,
						action: {
							isPresentingDeleteConfirmation = true
						},
					)
                    .disabled(selectedEventIds.count == 0)
					.goalProgressEventDeleteConfirmationDialog(
						isPresented: $isPresentingDeleteConfirmation,
						eventCount: selectedEventIds.count,
						onDelete: deleteSelectedEvents,
					)
				}
			} else {
				ToolbarItem(placement: .topBarTrailing) {
					Menu {
                        Button {
                            withAnimation {
                                editMode = .active
                            }
                        } label: {
							Label("Select Events", systemImage: "checkmark.circle")
						}
						.disabled(events.isEmpty)
						Menu {
							Picker("Sort", selection: $sortOrder) {
								ForEach(GoalProgressEventSortOrder.allCases) { sortOrder in
									Text(sortOrder.title)
										.tag(sortOrder)
								}
							}
						} label: {
							Label("Sort By", systemImage: "arrow.up.arrow.down")
						}
					} label: {
						Label("List Options", systemImage: "ellipsis")
					}
				}
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

	private var eventIds: Set<GoalProgressEvent.ID> {
		Set(events.map(\.id))
	}
    
	private var allEventsAreSelected: Bool {
        !eventIds.isEmpty && selectedEventIds.count == eventIds.count
	}

	private var selectAllButtonTitle: String {
        allEventsAreSelected ? "Deselect All" : "Select All"
	}

	private var goalManager: GoalManager {
		GoalManager(modelContext: modelContext)
	}

	private func exitEditMode() {
		selectedEventIds.removeAll()
		isPresentingDeleteConfirmation = false
        withAnimation {
            editMode = .inactive
        }
	}

	private func toggleSelectAllEvents() {
		if allEventsAreSelected {
			selectedEventIds.removeAll()
		} else {
			selectedEventIds = eventIds
		}
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

	private func deleteSelectedEvents() {
		guard !selectedEventIds.isEmpty else {
			return
		}
		do {
			let didDelete = try withAnimation {
				try goalManager.deleteProgressEvents(ids: selectedEventIds, from: goal)
			}
			if didDelete {
				exitEditMode()
			} else {
				deletionFailure = .blockedBatch
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
