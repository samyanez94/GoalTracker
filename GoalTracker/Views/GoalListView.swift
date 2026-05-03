//
//  GoalListView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftUI

struct GoalListView: View {
    let goalStore: GoalStore

    @State private var isPresentingCreateGoalView = false

    var body: some View {
        NavigationStack {
            List {
                Section("Pending") {
                    ForEach(goalStore.pendingGoals) { goal in
                        goalRow(for: goal)
                    }
                }
                Section("Completed") {
                    ForEach(goalStore.completedGoals) { goal in
                        goalRow(for: goal)
                    }
                }
            }
            .navigationTitle("Goals")
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    AddGoalButton {
                        isPresentingCreateGoalView = true
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 8)
                }
            }
            .navigationDestination(isPresented: $isPresentingCreateGoalView) {
                CreateGoalView { name, description in
                    goalStore.addGoal(name: name, description: description)
                }
            }
        }
    }

    private func goalRow(for goal: Goal) -> some View {
        NavigationLink {
            GoalDetailView(
                goal: goal,
                onSave: goalStore.updateGoal,
                onDelete: {
                    goalStore.deleteGoal(id: goal.id)
                },
            )
        } label: {
            Text(goal.name)
        }
        .swipeActions {
            Button(role: .destructive) {
                goalStore.deleteGoal(id: goal.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

private struct AddGoalButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(.tint, in: Circle())
        }
        .accessibilityLabel("Add Goal")
    }
}

#Preview {
    GoalListView(goalStore: GoalStore(goals: []))
}
