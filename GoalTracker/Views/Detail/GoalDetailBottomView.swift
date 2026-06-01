//
//  GoalDetailBottomActionView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftData
import SwiftUI

struct GoalDetailBottomView: View {

	let goal: Goal

	let openProgressUpdateView: () -> Void

	@Environment(\.modelContext) private var modelContext

	@State private var feedbackTrigger = false

	@State private var saveFailure: GoalSaveFailure?

	var body: some View {
		Group {
			switch goal.progress {
			case .outcome:
				CompleteGoalButton(
					isCompleted: goal.isCompleted(),
					action: completeGoal
				)
			case .measurable:
				HStack(spacing: 6) {
					ProgressStepperControl(
						canDecrement: goal.canDecrementProgress(),
						canIncrement: goal.canIncrementProgress(),
						onDecrement: decrementProgress,
						onIncrement: incrementProgress,
					)
					UpdateProgressButton(action: openProgressUpdateView)
				}
				.frame(maxWidth: .infinity)
				.padding(.horizontal)
			}
		}
		.sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger)
		.goalSaveFailureAlert(failure: $saveFailure)
	}

	private var goalManager: GoalManager {
		GoalManager(modelContext: modelContext)
	}

	private func completeGoal() {
		do {
			guard try goalManager.completeGoal(goal) else {
				return
			}
			feedbackTrigger.toggle()
		} catch {
			saveFailure = .updateProgress
		}
	}

	private func decrementProgress() {
		do {
			guard try goalManager.decrementProgress(goal) else {
				return
			}
			feedbackTrigger.toggle()
		} catch {
			saveFailure = .updateProgress
		}
	}

	private func incrementProgress() {
		do {
			guard try goalManager.incrementProgress(goal) else {
				return
			}
			feedbackTrigger.toggle()
		} catch {
			saveFailure = .updateProgress
		}
	}
}

// MARK: - Previews

#Preview("Outcome") {
	GoalDetailBottomView(
		goal: Goal(
			name: "Climb Mount Kilimanjaro",
			details: "Reach the summit of Mount Kilimanjaro by the end of the year.",
			createdAt: Date(),
			progress: .outcome(OutcomeProgress()),
		),
		openProgressUpdateView: {},
	)
}

#Preview("Measurable") {
	GoalDetailBottomView(
		goal: Goal(
			name: "Read 10 books",
			details: "Keep a steady reading habit.",
			createdAt: Date(),
			progress: .measurable(
				currentValue: 1,
				targetValue: 10,
				unit: .custom(
					title: "Books",
					abbreviatedTitle: "Books",
				),
			),
		),
		openProgressUpdateView: {},
	)
}
