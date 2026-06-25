//
//  GoalListView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftData
import SwiftUI

// MARK: - GoalListView

struct GoalListView: View {
	@Environment(\.modelContext) private var modelContext

	@Query private var goals: [Goal]

	@State private var navigationPath: [GoalNavigationDestination] = []

	@State private var editMode = EditMode.inactive

	@State private var isPresentingGoalFormView = false

	@State private var isPresentingDeleteConfirmation = false

	@State private var saveFailure: GoalSaveFailure?

	@State private var searchText = ""

	@State private var selectedGoalIds = Set<UUID>()

	@AppStorage(AppStorageKey.goalSortMode) private var sortMode: GoalSortMode = .creationDate

	@AppStorage(AppStorageKey.goalSortDirection) private var sortDirection: GoalSortDirection =
		.descending

	@AppStorage(AppStorageKey.isShowingCompletedGoals) private var isShowingCompletedGoals = true

	@AppStorage(AppStorageKey.isPendingSectionExpanded) private var storedPendingSectionExpanded = true

	@AppStorage(AppStorageKey.isCompletedSectionExpanded) private var storedCompletedSectionExpanded =
		true

	@State private var isPendingSectionExpanded: Bool

	@State private var isCompletedSectionExpanded: Bool

	private let sorter = GoalSorter()

	private let searchFilter = GoalSearchFilter()

	private let notificationRouter: GoalNotificationRouter

	init(notificationRouter: GoalNotificationRouter = GoalNotificationRouter()) {
		self.notificationRouter = notificationRouter
		_isPendingSectionExpanded = State(
			initialValue: Self.storedBool(
				for: AppStorageKey.isPendingSectionExpanded,
				defaultValue: true
			)
		)
		_isCompletedSectionExpanded = State(
			initialValue: Self.storedBool(
				for: AppStorageKey.isCompletedSectionExpanded,
				defaultValue: true
			)
		)
	}

	var body: some View {
		NavigationStack(path: $navigationPath) {
			Group {
				if goals.isEmpty {
					GoalUnavailableView.emptyGoals()
				} else if isSearching,
					visibleSearchResultsAreEmpty
				{
					GoalUnavailableView.emptySearch()
				} else if pendingGoalsAreHiddenByCompletedFilter {
					GoalUnavailableView.emptyPendingGoals()
				} else {
					List(selection: goalSelection) {
						if isShowingCompletedGoals {
							if !pendingGoals.isEmpty {
								Section(
									String(localized: .goalListSectionPending),
									isExpanded: $isPendingSectionExpanded
								) {
									ForEach(pendingGoals) { goal in
										GoalRowView(goal: goal)
									}
								}
							}
							if !completedGoals.isEmpty {
								Section(
									String(localized: .goalListSectionCompleted),
									isExpanded: $isCompletedSectionExpanded
								) {
									ForEach(completedGoals) { goal in
										GoalRowView(goal: goal)
									}
								}
							}
						} else {
							ForEach(pendingGoals) { goal in
								GoalRowView(goal: goal)
							}
						}
					}
					.listStyle(.sidebar)
				}
			}
			.navigationTitle(.goalListTitle)
			.environment(\.editMode, $editMode)
			.searchable(text: $searchText, prompt: Text(.goalListSearchPrompt))
			.toolbar {
				GoalListBottomToolbar(
					isSelectingGoals: editMode.isEditing,
					selectedGoalCount: selectedGoals.count,
					onAddGoal: {
						isPresentingGoalFormView = true
					},
					isPresentingDeleteConfirmation: $isPresentingDeleteConfirmation,
					deleteSelectedGoals: deleteSelectedGoals
				)
				GoalListTopToolbar(
					sortMode: $sortMode,
					sortDirection: $sortDirection,
					isShowingCompletedGoals: $isShowingCompletedGoals,
					isEditing: editMode.isEditing,
					isEditModeEnabled: !goals.isEmpty,
					enterEditMode: enterEditMode,
					exitEditMode: exitEditMode
				)
			}
			.sheet(isPresented: $isPresentingGoalFormView) {
				NavigationStack {
					GoalFormView(mode: .create) { data in
						try goalManager.addGoal(with: data)
					}
				}
			}
			.navigationDestination(for: GoalNavigationDestination.self) { destination in
				destinationView(for: destination)
			}
			.onChange(of: notificationRouter.pendingGoalId) { _, goalId in
				navigateToGoalIfPossible(goalId)
			}
			.onChange(of: isPendingSectionExpanded) { _, isExpanded in
				storedPendingSectionExpanded = isExpanded
			}
			.onChange(of: isCompletedSectionExpanded) { _, isExpanded in
				storedCompletedSectionExpanded = isExpanded
			}
			.onChange(of: goals.map(\.id)) { _, _ in
				navigateToGoalIfPossible(notificationRouter.pendingGoalId)
			}
			.onAppear {
				navigateToGoalIfPossible(notificationRouter.pendingGoalId)
			}
			.goalSaveFailureAlert(failure: $saveFailure)
		}
	}

	private var goalManager: GoalManager {
		GoalManager(modelContext: modelContext)
	}

	private var isSearching: Bool {
		!searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	private var searchedGoals: [Goal] {
		searchFilter.filtered(
			goals,
			searchText: searchText,
		)
	}

	private var visibleSearchResultsAreEmpty: Bool {
		pendingGoals.isEmpty && (!isShowingCompletedGoals || completedGoals.isEmpty)
	}

	private var pendingGoalsAreHiddenByCompletedFilter: Bool {
		!isShowingCompletedGoals && pendingGoals.isEmpty
	}

	private var pendingGoals: [Goal] {
		sorter.sorted(
			searchedGoals.filter { !$0.isCompleted() },
			by: sortMode,
			direction: sortDirection,
		)
	}

	private var completedGoals: [Goal] {
		sorter.sorted(
			searchedGoals.filter { $0.isCompleted() },
			by: sortMode,
			direction: sortDirection,
		)
	}

	private var selectedGoals: [Goal] {
		goals.filter { goal in
			selectedGoalIds.contains(goal.id)
		}
	}

	private var goalSelection: Binding<Set<UUID>>? {
		editMode.isEditing ? $selectedGoalIds : nil
	}

	private static func storedBool(for key: String, defaultValue: Bool) -> Bool {
		UserDefaults.standard.object(forKey: key) as? Bool ?? defaultValue
	}

	private func enterEditMode() {
		withAnimation {
			selectedGoalIds.removeAll()
			editMode = .active
		}
	}

	private func exitEditMode() {
		withAnimation {
			selectedGoalIds.removeAll()
			editMode = .inactive
		}
	}

	private func deleteSelectedGoals() {
		guard !selectedGoals.isEmpty else {
			return
		}
		do {
			try withAnimation {
				try goalManager.deleteGoals(selectedGoals)
			}
			exitEditMode()
		} catch {
			saveFailure = .deleteGoal
		}
	}

	@ViewBuilder
	private func destinationView(for destination: GoalNavigationDestination) -> some View {
		switch destination {
		case .goal(let goalId):
			if let goal = goal(with: goalId) {
				GoalDetailView(goal: goal)
			} else {
				GoalUnavailableView.goalNotFound()
			}
		case .progressEvents(let goalId):
			if let goal = goal(with: goalId) {
				GoalProgressEventListView(goal: goal)
			} else {
				GoalUnavailableView.goalNotFound()
			}
		}
	}

	private func navigateToGoalIfPossible(_ goalId: UUID?) {
		guard let goalId,
			goal(with: goalId) != nil
		else {
			return
		}
		exitEditMode()
		isPresentingGoalFormView = false
		isPresentingDeleteConfirmation = false
		navigationPath = [.goal(goalId)]
		notificationRouter.pendingGoalId = nil
	}

	private func goal(with id: UUID) -> Goal? {
		goals.first { goal in
			goal.id == id
		}
	}
}

// MARK: - Previews

#if DEBUG

#Preview("No goals") {
	let container = GoalPreviewContainer.make(
		goals: [],
	)
	GoalListView().modelContainer(container)
}

#Preview("Three goals") {
	let container = GoalPreviewContainer.make(
		goals: [
			Goal(
				name: "Travel to Switzerland",
				progress: .outcome(OutcomeProgress.completed(timestamp: Date())),
			),
			Goal(
				name: "Climb Mount Kilimanjaro",
				progress: .outcome(OutcomeProgress()),
			),
			Goal(
				name: "Run 10 marathons",
				progress: .measurable(
					currentValue: 2,
					targetValue: 10
				),
			)
		],
	)
	GoalListView().modelContainer(container)
}

#endif
