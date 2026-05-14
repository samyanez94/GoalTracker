//
//  GoalDetailBottomActionView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct GoalDetailBottomActionView: View {
    let goal: Goal
    let goalId: Goal.ID
    let goalStore: GoalStore
    @Binding var feedbackTrigger: Bool
    let onDismiss: () -> Void

    var body: some View {
        if let progress {
            ProgressStepperControl(
                canDecrement: progress.canDecrement,
                canIncrement: progress.canIncrement,
                onDecrement: decrementProgress,
                onIncrement: incrementProgress,
            )
        } else {
            CompleteGoalButton(isCompleted: goal.isCompleted) {
                if goalStore.completeGoal(id: goalId) {
                    feedbackTrigger.toggle()
                }
                onDismiss()
            }
        }
    }

    private var progress: GoalProgress? {
        goal.progress.isMeasurable ? goal.progress : nil
    }

    private func decrementProgress() {
        guard goalStore.decrementProgress(id: goalId) else {
            return
        }
        feedbackTrigger.toggle()
    }

    private func incrementProgress() {
        guard goalStore.incrementProgress(id: goalId) else {
            return
        }
        feedbackTrigger.toggle()
    }
}
