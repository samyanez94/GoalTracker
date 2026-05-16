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

    @State private var isPresentingGoalFormView = false

    @State private var saveFailure: GoalSaveFailure?

    @State private var searchText = ""

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
                    List {
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
                            }
                        }
                    }
                }
            }
            .navigationTitle("Goals")
            .searchable(text: $searchText, prompt: "Search goals")
            .toolbar {
                GoalListBottomToolbar {
                    isPresentingGoalFormView = true
                }
                GoalListTopToolbar(
                    sortMode: $sortMode,
                    sortDirection: $sortDirection,
                    isShowingCompletedGoals: $isShowingCompletedGoals,
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
