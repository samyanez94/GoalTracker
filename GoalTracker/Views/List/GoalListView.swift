//
//  GoalListView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftData
import SwiftUI

struct GoalListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var goals: [Goal]

    @State private var editMode = EditMode.inactive

    @State private var isPresentingGoalFormView = false

    @State private var saveFailure: GoalSaveFailure?

    @State private var searchText = ""

    @State private var selectedGoalIDs = Set<UUID>()

    @AppStorage(AppStorageKey.goalSortMode) private var sortMode: GoalSortMode = .creationDate

    @AppStorage(AppStorageKey.goalSortDirection) private var sortDirection: GoalSortDirection = .descending

    @AppStorage(AppStorageKey.isShowingCompletedGoals) private var isShowingCompletedGoals = true

    @AppStorage(AppStorageKey.isPendingSectionExpanded) private var isPendingSectionExpanded = true

    @AppStorage(AppStorageKey.isCompletedSectionExpanded) private var isCompletedSectionExpanded = true

    private let sorter = GoalSorter()

    private let searchFilter = GoalSearchFilter()

    var body: some View {
        NavigationStack {
            Group {
                if goals.isEmpty {
                    Text("No goals")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isSearching, visibleSearchResultsAreEmpty {
                    Text("No matching goals")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(selection: $selectedGoalIDs) {
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
                    isSelectingGoals: isSelectingGoals,
                    selectedGoalCount: selectedGoals.count,
                    onAddGoal: {
                        isPresentingGoalFormView = true
                    },
                    onDeleteSelectedGoals: {
                        deleteSelectedGoals()
                    }
                )
                GoalListTopToolbar(
                    sortMode: $sortMode,
                    sortDirection: $sortDirection,
                    isShowingCompletedGoals: $isShowingCompletedGoals,
                    isSelectingGoals: isSelectingGoals,
                    canSelectGoals: !visibleSelectableGoals.isEmpty,
                    onSelectGoals: {
                        editMode = .active
                    },
                    onFinishSelectingGoals: {
                        finishSelectingGoals()
                    }
                )
            }
            .sheet(isPresented: $isPresentingGoalFormView) {
                NavigationStack {
                    GoalFormView(mode: .create) { data in
                        try goalManager.addGoal(
                            Goal(
                                name: data.name,
                                details: data.normalizedDetails,
                                dueDate: data.dueDate,
                                createdAt: Date(),
                                progress: data.progress,
                            ),
                        )
                    }
                }
            }
            .navigationDestination(for: Goal.self) { goal in
                GoalDetailView(goal: goal)
            }
            .goalSaveFailureAlert(failure: $saveFailure)
            .onChange(of: visibleGoalIDs) { _, _ in
                pruneSelectedGoalIDs()
            }
        }
    }

    private var goalManager: GoalManager {
        GoalManager(modelContext: modelContext)
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isSelectingGoals: Bool {
        editMode.isEditing
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

    private var pendingGoals: [Goal] {
        sorter.sorted(
            searchedGoals.filter { !$0.isCompleted },
            by: sortMode,
            direction: sortDirection,
        )
    }

    private var completedGoals: [Goal] {
        sorter.sorted(
            searchedGoals.filter(\.isCompleted),
            by: sortMode,
            direction: sortDirection,
        )
    }

    private var visibleSelectableGoals: [Goal] {
        if isShowingCompletedGoals {
            let visiblePendingGoals = isPendingSectionExpanded ? pendingGoals : []
            let visibleCompletedGoals = isCompletedSectionExpanded ? completedGoals : []
            return visiblePendingGoals + visibleCompletedGoals
        } else {
            return pendingGoals
        }
    }

    private var visibleGoalIDs: Set<UUID> {
        Set(visibleSelectableGoals.map(\.id))
    }

    private var selectedGoals: [Goal] {
        visibleSelectableGoals.filter { goal in
            selectedGoalIDs.contains(goal.id)
        }
    }

    private func finishSelectingGoals() {
        selectedGoalIDs.removeAll()
        editMode = .inactive
    }

    private func deleteSelectedGoals() {
        pruneSelectedGoalIDs()
        guard !selectedGoals.isEmpty else {
            return
        }
        do {
            try goalManager.deleteGoals(selectedGoals)
            finishSelectingGoals()
        } catch {
            saveFailure = .deleteGoal
        }
    }

    private func pruneSelectedGoalIDs() {
        selectedGoalIDs.formIntersection(visibleGoalIDs)
    }
}

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
                details: nil,
                createdAt: Date(),
                progress: .outcomeCompleted,
            ),
            Goal(
                name: "Climb Mount Kilimanjaro",
                details: nil,
                createdAt: Date(),
                progress: .outcomePending,
            ),
            Goal(
                name: "Run 10 marathons",
                details: nil,
                createdAt: Date(),
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
