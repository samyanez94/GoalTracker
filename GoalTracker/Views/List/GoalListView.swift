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

	@Environment(\.goalReminderCoordinator) private var reminderCoordinator

	@Environment(\.goalKeyboardState) private var keyboardState

	@Query private var goals: [Goal]

	@Bindable private var navigation: GoalNavigationState

	@State private var editMode = EditMode.inactive

	@State private var isPresentingGoalFormView = false

	@State private var isPresentingDeleteConfirmation = false

	@State private var saveFailure: GoalSaveFailure?

	@State private var searchText = ""

	@FocusState private var isSearchFocused: Bool

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

	private let onRevealSidebar: () -> Void

	init(
		navigation: GoalNavigationState,
		notificationRouter: GoalNotificationRouter,
		onRevealSidebar: @escaping () -> Void
	) {
		self.navigation = navigation
		self.notificationRouter = notificationRouter
		self.onRevealSidebar = onRevealSidebar
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
				Group {
					if editMode.isEditing {
						List(selection: $selectedGoalIds) {
							GoalListSectionsView(
								pendingGoals: pendingGoals,
								completedGoals: completedGoals,
								isShowingCompletedGoals: isShowingCompletedGoals,
								isPendingSectionExpanded: $isPendingSectionExpanded,
								isCompletedSectionExpanded: $isCompletedSectionExpanded
							)
						}
					} else {
						List(selection: navigationSelection) {
							GoalListSectionsView(
								pendingGoals: pendingGoals,
								completedGoals: completedGoals,
								isShowingCompletedGoals: isShowingCompletedGoals,
								isPendingSectionExpanded: $isPendingSectionExpanded,
								isCompletedSectionExpanded: $isCompletedSectionExpanded
							)
						}
					}
				}
				.listStyle(.sidebar)
			}
		}
		.navigationTitle(.goalListTitle)
		.environment(\.editMode, $editMode)
		.searchable(text: $searchText, prompt: Text(.goalListSearchPrompt))
		.searchFocused($isSearchFocused)
		.focusedSceneValue(\.goalKeyboardActions, keyboardActions)
		.toolbar {
			GoalListBottomToolbar(
				isSelectingGoals: editMode.isEditing,
				selectedGoalCount: selectedGoals.count,
				onAddGoal: presentGoalForm,
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
			.presentationSizing(.form)
			.goalFormKeyboardScope()
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

	private var goalManager: GoalManager {
		GoalManager(modelContext: modelContext, reminderCoordinator: reminderCoordinator)
	}

	private var canRunMainCommands: Bool {
		!isPresentingGoalFormView && keyboardState?.isPresentingForm != true
	}

	private var keyboardActions: GoalKeyboardActions {
		guard canRunMainCommands else {
			return GoalKeyboardActions()
		}
		return GoalKeyboardActions(addGoal: presentGoalForm, searchGoals: searchGoalsFromKeyboard)
	}

	private func presentGoalForm() {
		guard canRunMainCommands else {
			return
		}
		isPresentingGoalFormView = true
	}

	private func searchGoalsFromKeyboard() {
		guard canRunMainCommands else {
			return
		}
		exitEditMode()
		onRevealSidebar()
		isSearchFocused = true
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

	private var navigationSelection: Binding<UUID?> {
		Binding {
			navigation.selectedGoalID
		} set: { goalID in
			// Removing the single-selection list can clear its binding as edit mode starts.
			navigation.updateSidebarSelection(goalID, isEditing: editMode.isEditing)
		}
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

	private func navigateToGoalIfPossible(_ goalId: UUID?) {
		guard let goalId,
			goal(with: goalId) != nil
		else {
			return
		}
		exitEditMode()
		isPresentingGoalFormView = false
		isPresentingDeleteConfirmation = false
		navigation.selectedGoalID = goalId
		navigation.detailPath.removeAll()
		notificationRouter.pendingGoalId = nil
	}

	private func goal(with id: UUID) -> Goal? {
		goals.first { goal in
			goal.id == id
		}
	}
}
