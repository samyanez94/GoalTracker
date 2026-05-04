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

    @State private var isPendingSectionExpanded = true

    @State private var isCompletedSectionExpanded = true

    var body: some View {
        NavigationStack {
            List {
                if !goalStore.pendingGoals.isEmpty {
                    Section(isExpanded: $isPendingSectionExpanded) {
                        ForEach(goalStore.pendingGoals) { goal in
                            GoalRowView(
                                goal: goal,
                                onSave: { goal in
                                    goalStore.updateGoal(goal)
                                },
                                onDelete: { goal in
                                    goalStore.deleteGoal(id: goal.id)
                                },
                            )
                        }
                    } header: {
                        CollapsibleSectionHeader(
                            title: "Pending",
                            isExpanded: $isPendingSectionExpanded,
                        )
                    }
                }
                if !goalStore.completedGoals.isEmpty {
                    Section(isExpanded: $isCompletedSectionExpanded) {
                        ForEach(goalStore.completedGoals) { goal in
                            GoalRowView(
                                goal: goal,
                                onSave: { goal in
                                    goalStore.updateGoal(goal)
                                },
                                onDelete: { goal in
                                    goalStore.deleteGoal(id: goal.id)
                                },
                            )
                        }
                    } header: {
                        CollapsibleSectionHeader(
                            title: "Completed",
                            isExpanded: $isCompletedSectionExpanded,
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
                            Goal(
                                name: data.name,
                                description: data.description,
                                createdAt: Date(),
                                completion: data.completion,
                            ),
                        )
                    }
                }
            }
        }
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
