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

    @State private var sortMode: GoalSortMode = .manual

    @State private var isShowingCompletedGoals = true

    @State private var isPendingSectionExpanded = true

    @State private var isCompletedSectionExpanded = true

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
                                sortMode: $sortMode,
                                onMove: movePendingGoals,
                            )
                            GoalSectionView(
                                title: "Completed",
                                goals: completedGoals,
                                isExpanded: $isCompletedSectionExpanded,
                                goalManager: goalManager,
                                sortMode: $sortMode,
                                onMove: moveCompletedGoals,
                            )
                        } else {
                            GoalRowsView(
                                goals: pendingGoals,
                                goalManager: goalManager,
                                sortMode: $sortMode,
                                onMove: movePendingGoals,
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
                        goalManager.addGoal(
                            Goal(
                                name: data.name,
                                details: data.normalizedDetails,
                                dueDate: data.dueDate,
                                createdAt: Date(),
                                progress: data.progress,
                            ),
                            in: goals,
                        )
                    }
                }
            }
            .navigationDestination(for: Goal.ID.self) { goalId in
                GoalDetailView(goalId: goalId)
            }
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

    private func movePendingGoals(
        from source: IndexSet,
        to destination: Int,
        sortedBy sortMode: GoalSortMode,
    ) {
        goalManager.movePendingGoals(
            in: goals,
            from: source,
            to: destination,
            sortedBy: sortMode,
        )
    }

    private func moveCompletedGoals(
        from source: IndexSet,
        to destination: Int,
        sortedBy sortMode: GoalSortMode,
    ) {
        goalManager.moveCompletedGoals(
            in: goals,
            from: source,
            to: destination,
            sortedBy: sortMode,
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
