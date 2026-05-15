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

    @AppStorage(AppStorageKey.goalSortMode) private var sortMode: GoalSortMode = .creationDate

    @AppStorage(AppStorageKey.isShowingCompletedGoals) private var isShowingCompletedGoals = true

    @AppStorage(AppStorageKey.isPendingSectionExpanded) private var isPendingSectionExpanded = true

    @AppStorage(AppStorageKey.isCompletedSectionExpanded) private var isCompletedSectionExpanded = true

    private let sorter = GoalSorter()

    var body: some View {
        NavigationStack {
            Group {
                if goals.isEmpty {
                    Text("No goals yet")
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
                                goalManager: goalManager,
                            )
                            GoalSectionView(
                                title: "Completed",
                                goals: completedGoals,
                                isExpanded: $isCompletedSectionExpanded,
                                goalManager: goalManager,
                            )
                        } else {
                            GoalRowsView(
                                goals: pendingGoals,
                                goalManager: goalManager,
                            )
                        }
                    }
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isShowingCompletedGoals.toggle()
                        } label: {
                            Label(
                                isShowingCompletedGoals ? "Hide Completed" : "Show Completed",
                                systemImage: isShowingCompletedGoals ? "eye.slash" : "eye",
                            )
                        }
                        Menu {
                            Picker("Sort", selection: $sortMode) {
                                ForEach(GoalSortMode.allCases) { sortMode in
                                    Text(sortMode.title)
                                        .tag(sortMode)
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
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    AddGoalButton {
                        isPresentingGoalFormView = true
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 8)
                }
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
            .navigationDestination(for: Goal.ID.self) { goalId in
                GoalDetailView(goalId: goalId)
            }
            .goalSaveFailureAlert(failure: $saveFailure)
        }
    }

    private var goalManager: GoalManager {
        GoalManager(modelContext: modelContext)
    }

    private var pendingGoals: [Goal] {
        sorter.sorted(
            goals.filter { !$0.isCompleted },
            by: sortMode,
        )
    }

    private var completedGoals: [Goal] {
        sorter.sorted(
            goals.filter(\.isCompleted),
            by: sortMode,
        )
    }

}

#Preview {
    let container = GoalPreviewContainer.make(
        goals: [
            Goal(
                name: "Run 100 miles",
                details: nil,
                createdAt: Date(),
                progress: .measurable(
                    currentValue: 20,
                    targetValue: 100,
                ),
            )
        ],
    )

    GoalListView()
        .modelContainer(container)
}
