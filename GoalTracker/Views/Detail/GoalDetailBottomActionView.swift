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
    let goals: [Goal]
    let goalManager: GoalManager
    @Binding var feedbackTrigger: Bool
    let onDismiss: () -> Void

    @State private var saveFailure: GoalSaveFailure?

    var body: some View {
        Group {
            if let progress {
                ProgressStepperControl(
                    canDecrement: progress.canDecrement,
                    canIncrement: progress.canIncrement,
                    onDecrement: decrementProgress,
                    onIncrement: incrementProgress,
                )
            } else {
                CompleteGoalButton(isCompleted: goal.isCompleted) {
                    do {
                        guard try goalManager.completeGoal(id: goalId, in: goals) else {
                            return
                        }
                        feedbackTrigger.toggle()
                        onDismiss()
                    } catch {
                        saveFailure = .updateProgress
                    }
                }
            }
        }
        .goalSaveFailureAlert(failure: $saveFailure)
    }

    private var progress: GoalProgress? {
        goal.progress.isMeasurable ? goal.progress : nil
    }

    private func decrementProgress() {
        do {
            guard try goalManager.decrementProgress(id: goalId, in: goals) else {
                return
            }
            feedbackTrigger.toggle()
        } catch {
            saveFailure = .updateProgress
        }
    }

    private func incrementProgress() {
        do {
            guard try goalManager.incrementProgress(id: goalId, in: goals) else {
                return
            }
            feedbackTrigger.toggle()
        } catch {
            saveFailure = .updateProgress
        }
    }
}
