//
//  GoalDetailBottomActionView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftData
import SwiftUI

struct GoalDetailBottomActionView: View {
    @Environment(\.modelContext) private var modelContext

    let goal: Goal

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
                    Task { @MainActor in
                        do {
                            guard try await goalManager.completeGoal(goal) else {
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
        }
        .goalSaveFailureAlert(failure: $saveFailure)
    }

    private var goalManager: GoalManager {
        GoalManager(modelContext: modelContext)
    }

    private var progress: GoalProgress? {
        goal.progress.isMeasurable ? goal.progress : nil
    }

    private func decrementProgress() {
        Task { @MainActor in
            do {
                guard try await goalManager.decrementProgress(goal) else {
                    return
                }
                feedbackTrigger.toggle()
            } catch {
                saveFailure = .updateProgress
            }
        }
    }

    private func incrementProgress() {
        Task { @MainActor in
            do {
                guard try await goalManager.incrementProgress(goal) else {
                    return
                }
                feedbackTrigger.toggle()
            } catch {
                saveFailure = .updateProgress
            }
        }
    }
}
