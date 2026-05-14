//
//  GoalListView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftUI

struct GoalListView: View {
    let goalStore: GoalStore

    @State private var isPresentingGoalFormView = false

    @State private var sortMode: GoalSortMode = .manual

    @State private var isShowingCompletedGoals = true

    @State private var isPendingSectionExpanded = true

    @State private var isCompletedSectionExpanded = true

    var body: some View {
        NavigationStack {
            Group {
                if goalStore.goals.isEmpty {
                    Text("No goals yet")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if isShowingCompletedGoals {
                            GoalSectionView(
                                title: "Pending",
                                goals: goalStore.pendingGoals(sortedBy: sortMode),
                                isExpanded: $isPendingSectionExpanded,
                                goalStore: goalStore,
                                sortMode: $sortMode,
                                onMove: movePendingGoals,
                            )
                            GoalSectionView(
                                title: "Completed",
                                goals: goalStore.completedGoals(sortedBy: sortMode),
                                isExpanded: $isCompletedSectionExpanded,
                                goalStore: goalStore,
                                sortMode: $sortMode,
                                onMove: moveCompletedGoals,
                            )
                        } else {
                            GoalRowsView(
                                goals: goalStore.pendingGoals(sortedBy: sortMode),
                                goalStore: goalStore,
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
                        goalStore.addGoal(
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
                GoalDetailView(
                    goalId: goalId,
                    goalStore: goalStore,
                )
            }
        }
    }

    private func movePendingGoals(
        from source: IndexSet,
        to destination: Int,
        sortedBy sortMode: GoalSortMode,
    ) {
        goalStore.movePendingGoals(
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
        goalStore.moveCompletedGoals(
            from: source,
            to: destination,
            sortedBy: sortMode,
        )
    }
}

#Preview {
    GoalListView(
        goalStore: GoalStore(
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
        ),
    )
}
