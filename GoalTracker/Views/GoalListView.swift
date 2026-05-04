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

    var body: some View {
        NavigationStack {
            List {
                Section("Pending") {
                    ForEach(goalStore.pendingGoals) { goal in
                        GoalRowView(
                            goal: goal,
                            onSave: { goal in goalStore.updateGoal(goal)
                            },
                            onDelete: { goal in
                                goalStore.deleteGoal(id: goal.id)
                            }
                        )
                    }
                }
                Section("Completed") {
                    ForEach(goalStore.completedGoals) { goal in
                        GoalRowView(
                            goal: goal,
                            onSave: { goal in goalStore.updateGoal(goal)
                            },
                            onDelete: { goal in
                                goalStore.deleteGoal(id: goal.id)
                            }
                        )
                    }
                }
            }
            .navigationTitle("Goals")
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
                    GoalFormView(title: "New Goal") { data in
                        goalStore.addGoal(
                            name: data.name,
                            description: data.description,
                            kind: data.kind,
                            progress: data.progress,
                        )
                    }
                }
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
