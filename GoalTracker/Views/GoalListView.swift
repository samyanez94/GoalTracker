//
//  GoalListView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftUI

struct GoalListView: View {
    @State var goals: [Goal] = [
        Goal(name: "First", description: nil, createdAt: Date(), isCompleted: false),
    ]

    @State private var isPresentingCreateGoalView = false

    var body: some View {
        NavigationStack {
            List {
                Section("Pending") {
                    ForEach(pendingGoals) { goal in
                        goalRow(for: goal)
                    }
                }
                Section("Completed") {
                    ForEach(completedGoals) { goal in
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
                CreateGoalView { goal in
                    goals.append(goal)
                }
            }
        }
    }

    private var pendingGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }

    private var completedGoals: [Goal] {
        goals.filter(\.isCompleted)
    }

    @ViewBuilder
    private func goalRow(for goal: Goal) -> some View {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            NavigationLink {
                GoalDetailView(goal: $goals[index]) {
                    deleteGoal(goal)
                }
            } label: {
                Text(goal.name)
            }
        }
    }

    private func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
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
    GoalListView()
}
