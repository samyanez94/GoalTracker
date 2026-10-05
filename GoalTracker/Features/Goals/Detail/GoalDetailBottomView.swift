//
//  GoalDetailBottomView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftData
import SwiftUI

// MARK: - GoalDetailBottomView

struct GoalDetailBottomView: View {

	let goal: Goal

	let openProgressUpdateView: () -> Void

	@Environment(\.modelContext) private var modelContext

	@Environment(GoalReminderCoordinator.self) private var reminderUpdates

	@State private var feedbackTrigger = false

	@State private var saveFailure: GoalSaveFailure?

	var body: some View {
		Group {
			switch goal.progress {
			case .outcome:
				let isCompleted = goal.isCompleted()
				let title: LocalizedStringResource = isCompleted ? .detailCompleteGoalButtonCompleted : .detailCompleteGoalButtonComplete
				Button(title, action: completeGoal)
					.font(.headline)
					.controlSize(.large)
					.buttonSizing(.flexible)
					.buttonStyle(.glassProminent)
					.disabled(isCompleted)
			case .measurable:
				HStack(spacing: 6) {
					ProgressStepperControl(
						canDecrement: goal.canDecrementProgress(),
						canIncrement: goal.canIncrementProgress(),
						onDecrement: decrementProgress,
						onIncrement: incrementProgress,
					)
					Button(
						.detailUpdateProgressButton,
						systemImage: "plus.forwardslash.minus",
						action: openProgressUpdateView
					)
					.font(.body.weight(.semibold))
					.labelStyle(.iconOnly)
					.controlSize(.large)
					.buttonStyle(.glassProminent)
					.buttonBorderShape(.circle)
				}
				.frame(maxWidth: .infinity)
			}
		}
		.sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger)
		.goalSaveFailureAlert(failure: $saveFailure)
	}

	private var goalService: GoalService {
		GoalService(modelContext: modelContext, reminderUpdates: reminderUpdates)
	}

	private func completeGoal() {
		do {
			guard try goalService.completeGoal(goal) else {
				return
			}
			feedbackTrigger.toggle()
		} catch {
			saveFailure = .updateProgress
		}
	}

	private func decrementProgress() {
		do {
			guard try goalService.decrementProgress(goal) else {
				return
			}
			feedbackTrigger.toggle()
		} catch {
			saveFailure = .updateProgress
		}
	}

	private func incrementProgress() {
		do {
			guard try goalService.incrementProgress(goal) else {
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
	.previewGoalReminders()
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
	.previewGoalReminders()
}
