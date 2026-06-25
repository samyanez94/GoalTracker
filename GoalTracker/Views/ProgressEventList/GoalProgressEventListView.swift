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
				GoalUnavailableView.emptyProgressEvents()
			} else {
				List(selection: eventSelection) {
					ForEach(eventSections) { section in
						Section(section.title) {
							ForEach(section.events) { event in
								GoalProgressEventRowView(
									event: event,
									unit: progress?.unit,
								)
								.swipeActions {
									Button(.commonDelete, systemImage: "trash", role: .destructive) {
										deleteEvent(event)
									}
								}
							}
						}
					}
				}
			}
		}
		.navigationTitle(.progressEventListTitle)
		.navigationBarTitleDisplayMode(.large)
		.environment(\.editMode, $editMode)
		.toolbar {
			if editMode.isEditing {
				ToolbarItem(placement: .topBarLeading) {
					Button(selectAllButtonTitle, action: toggleSelectAllEvents)
						.disabled(eventIds.isEmpty)
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button(.commonDone, systemImage: "checkmark", action: exitEditMode)
				}
				ToolbarItem(placement: .bottomBar) {
					Button(
						deleteSelectedEventsButtonTitle,
						systemImage: "trash",
						role: .destructive,
						action: {
							isPresentingDeleteConfirmation = true
						},
					)
					.disabled(selectedEventIds.count == 0)
					.accessibilityLabel(deleteButtonAccessibilityLabel)
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
								selectedEventIds.removeAll()
								editMode = .active
							}
						} label: {
							Label(.progressEventListSelectEvents, systemImage: "checkmark.circle")
						}
						.disabled(events.isEmpty)
						Menu {
							Picker(.commonSort, selection: $sortOrder) {
								ForEach(GoalProgressEventSortOrder.allCases) { sortOrder in
									Text(sortOrder.title)
										.tag(sortOrder)
								}
							}
						} label: {
							Label(.toolbarSortBy, systemImage: "arrow.up.arrow.down")
						}
					} label: {
						Label(.toolbarListOptions, systemImage: "ellipsis")
					}
				}
			}
		}
		.alert(item: $deletionFailure) { failure in
			Alert(
				title: Text(failure.title),
				message: Text(failure.message),
				dismissButton: .default(Text(.commonOk)),
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

	private var eventSelection: Binding<Set<GoalProgressEvent.ID>>? {
		editMode.isEditing ? $selectedEventIds : nil
	}

	private var allEventsAreSelected: Bool {
		!eventIds.isEmpty && selectedEventIds.count == eventIds.count
	}

	private var selectAllButtonTitle: LocalizedStringResource {
		allEventsAreSelected ? .commonDeselectAll : .commonSelectAll
	}

	private var deleteSelectedEventsButtonTitle: LocalizedStringResource {
		selectedEventIds.count == 1 ? .commonDeleteEvent : .commonDeleteEvents
	}

	private var deleteButtonAccessibilityLabel: LocalizedStringResource {
		switch selectedEventIds.count {
		case 0:
			.progressEventListDeleteSelectedEventsAccessibilityLabelNone
		default:
			.progressEventListDeleteSelectedEventsAccessibilityLabel(selectedEventIds.count)
		}
	}

	private var goalManager: GoalManager {
		GoalManager(modelContext: modelContext)
	}

	private func exitEditMode() {
		isPresentingDeleteConfirmation = false
		withAnimation {
			selectedEventIds.removeAll()
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

	private func deleteEvent(_ event: GoalProgressEvent) {
		deleteEvents([event.id])
	}

	private func deleteSelectedEvents() {
		if deleteEvents(selectedEventIds) {
			exitEditMode()
		}
	}

	@discardableResult
	private func deleteEvents(_ eventIdsToDelete: Set<GoalProgressEvent.ID>) -> Bool {
		guard !eventIdsToDelete.isEmpty else {
			return false
		}
		do {
			let didDelete = try withAnimation {
				try goalManager.deleteProgressEvents(ids: eventIdsToDelete, from: goal)
			}
			if didDelete {
				selectedEventIds.subtract(eventIdsToDelete)
				return true
			} else {
				deletionFailure = blockedDeletionFailure(for: eventIdsToDelete)
				return false
			}
		} catch {
			deletionFailure = .saveFailed
			return false
		}
	}

	private func blockedDeletionFailure(
		for eventIdsToDelete: Set<GoalProgressEvent.ID>
	) -> GoalProgressEventDeletionFailure {
		eventIdsToDelete.count == 1 ? .blocked : .blockedBatch
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
							)
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
