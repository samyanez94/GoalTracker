//
//  GoalListView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftUI
import UIKit

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
                    Text("No Goals")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if isShowingCompletedGoals {
                            goalSection(
                                title: "Pending",
                                goals: goalStore.pendingGoals(sortedBy: sortMode),
                                isExpanded: $isPendingSectionExpanded,
                                onMove: movePendingGoals,
                            )
                            goalSection(
                                title: "Completed",
                                goals: goalStore.completedGoals(sortedBy: sortMode),
                                isExpanded: $isCompletedSectionExpanded,
                                onMove: moveCompletedGoals,
                            )
                        } else {
                            goalRows(
                                goals: goalStore.pendingGoals(sortedBy: sortMode),
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
                                description: data.normalizedDescription,
                                dueDate: data.dueDate,
                                createdAt: Date(),
                                completion: data.completion,
                            ),
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func goalSection(
        title: String,
        goals: [Goal],
        isExpanded: Binding<Bool>,
        onMove: @escaping (IndexSet, Int, GoalSortMode) -> Void,
    ) -> some View {
        if !goals.isEmpty {
            Section(isExpanded: isExpanded) {
                goalRows(goals: goals, onMove: onMove)
            } header: {
                CollapsibleSectionHeader(
                    title: title,
                    isExpanded: isExpanded,
                )
            }
        }
    }

    private func goalRows(
        goals: [Goal],
        onMove: @escaping (IndexSet, Int, GoalSortMode) -> Void,
    ) -> some View {
        ForEach(goals) { goal in
            GoalRowView(
                goal: goal,
                goalStore: goalStore,
                onToggleCompletion: { goal in
                    toggleCompletion(for: goal)
                },
            )
        }
        .onMove { source, destination in
            defer {
                sortMode = .manual
            }
            onMove(source, destination, sortMode)
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

    private func toggleCompletion(for goal: Goal) {
        guard goalStore.toggleCompletion(id: goal.id) else {
            return
        }
        playHapticFeedback()
    }

    private func playHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

private struct CollapsibleSectionHeader: View {
    let title: String

    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            withAnimation {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
    }
}

private struct AddGoalButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            playHapticFeedback()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .frame(width: 56, height: 56)
        }
        .tint(.blue)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .shadow(
            color: .black.opacity(0.16),
            radius: 12, x: 0, y: 6,
        )
        .accessibilityLabel("Add Goal")
    }

    private func playHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#Preview {
    GoalListView(
        goalStore: GoalStore(
            goals: [
                Goal(
                    name: "Run 100 miles",
                    description: nil,
                    createdAt: Date(),
                    completion: .progress(
                        Goal.Progress(
                            currentValue: 20,
                            targetValue: 100,
                        ),
                    ),
                ),
            ],
        ),
    )
}
