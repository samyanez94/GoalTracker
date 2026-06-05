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

	@AppStorage(AppStorageKey.isPendingSectionExpanded) private var isPendingSectionExpanded = true

	@AppStorage(AppStorageKey.isCompletedSectionExpanded) private var isCompletedSectionExpanded =
		true

	private let sorter = GoalSorter()

	private let searchFilter = GoalSearchFilter()

	private let notificationRouter: GoalNotificationRouter

	init(notificationRouter: GoalNotificationRouter = GoalNotificationRouter()) {
		self.notificationRouter = notificationRouter
	}

	var body: some View {
		NavigationStack(path: $navigationPath) {
			Group {
				if goals.isEmpty {
					emptyStateView("No goals")
				} else if isSearching,
					visibleSearchResultsAreEmpty
				{
					emptyStateView("No matching goals")
				} else if pendingGoalsAreHiddenByCompletedFilter {
					emptyStateView("No pending goals")
				} else {
					List(selection: $selectedGoalIds) {
						if isShowingCompletedGoals {
							GoalSectionView(
								title: "Pending",
								goals: pendingGoals,
								isExpanded: $isPendingSectionExpanded,
							)
							GoalSectionView(
								title: "Completed",
								goals: completedGoals,
								isExpanded: $isCompletedSectionExpanded,
							)
						} else {
							ForEach(pendingGoals) { goal in
								GoalRowView(goal: goal)
									.tag(goal.id)
							}
						}
					}
				}
			}
			.navigationTitle("Goals")
			.environment(\.editMode, $editMode)
			.searchable(text: $searchText, prompt: "Search goals")
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

	private func emptyStateView(_ title: String) -> some View {
		Text(title)
			.font(.body)
			.foregroundStyle(.secondary)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color(.systemGroupedBackground))
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
    
    private func enterEditMode() {
        selectedGoalIds.removeAll()
        editMode = .active
    }

	private func exitEditMode() {
		selectedGoalIds.removeAll()
		editMode = .inactive
	}

	private func deleteSelectedGoals() {
		guard !selectedGoals.isEmpty else {
			return
		}
		do {
			try goalManager.deleteGoals(selectedGoals)
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
				EmptyView()
			}
		case .progressEvents(let goalId):
			if let goal = goal(with: goalId) {
				GoalProgressEventListView(goal: goal)
			} else {
				EmptyView()
			}
		}
	}

	private func navigateToGoalIfPossible(_ goalId: UUID?) {
		guard let goalId,
              goal(with: goalId) != nil else {
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

#Preview("No goals") {
	let container = GoalPreviewContainer.make(
		goals: [],
	)
	GoalListView()
		.modelContainer(container)
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
	GoalListView()
		.modelContainer(container)
}
