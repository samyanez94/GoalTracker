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
                    ForEach(pendingGoalIndices, id: \.self) { index in
                        goalRow(at: index)
                    }
                }
                Section("Completed") {
                    ForEach(completedGoalIndices, id: \.self) { index in
                        goalRow(at: index)
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

    private var pendingGoalIndices: [Int] {
        goals.indices.filter { !goals[$0].isCompleted }
    }

    private var completedGoalIndices: [Int] {
        goals.indices.filter { goals[$0].isCompleted }
    }

    @ViewBuilder
    private func goalRow(at index: Int) -> some View {
        if goals.indices.contains(index) {
            let goalId = goals[index].id
            NavigationLink {
                GoalDetailView(goal: $goals[index]) {
                    deleteGoal(id: goalId)
                }
            } label: {
                Text(goals[index].name)
            }
            .swipeActions {
                Button(role: .destructive) {
                    deleteGoal(id: goalId)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func deleteGoal(id: Goal.ID) {
        goals.removeAll { $0.id == id }
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
