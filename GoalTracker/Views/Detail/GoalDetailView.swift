//
//  GoalDetailView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftData
import SwiftUI

// MARK: - GoalDetailView

struct GoalDetailView: View {
	@Environment(\.dismiss) private var dismiss

	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	@Environment(\.modelContext) private var modelContext

	@Environment(\.goalReminderFeedback) private var reminderFeedback

	@State private var isPresentingEditForm = false

	@State private var isPresentingDeleteConfirmation = false

	@State private var isPresentingProgressUpdateSheet = false

	@State private var saveFailure: GoalSaveFailure?

	let goal: Goal

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 24) {
				if let reminderFeedback,
					let issue = reminderFeedback.issue(for: goal.id)
				{
					GoalReminderFeedbackView(
						feedback: reminderFeedback,
						issue: issue,
						modelContext: modelContext,
					)
					.transition(
						reduceMotion
							? .opacity.animation(.easeInOut(duration: 0.15))
							: .move(edge: .top).combined(with: .opacity)
					)
				}
				GoalDetailHeaderSection(goal: goal)
				if goal.isRecurring {
					GoalDetailStreakSection(goal: goal)
				}
				switch goal.progress {
				case .outcome:
					GoalDetailStatusSection(goal: goal)
				case .measurable(let progress):
					GoalDetailProgressSection(
						goalId: goal.id,
						recurrence: goal.recurrence,
						progress: progress,
						completedFooterText: goal.detailCompletionFooterText(),
					)
				}
			}
			.animation(reduceMotion ? nil : .smooth(duration: 0.25), value: isShowingReminderIssue)
		}
		.safeAreaPadding(.horizontal)
		.background(Color(.systemGroupedBackground).ignoresSafeArea())
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Menu(.detailGoalActions, systemImage: "ellipsis") {
					GoalActionMenuContent(
						isCompleted: goal.isCompleted(),
						edit: {
							isPresentingEditForm = true
						},
						toggleCompletion: toggleCompletion,
						delete: {
							isPresentingDeleteConfirmation = true
						},
					)
				}
				.goalDeleteConfirmationDialog(
					isPresented: $isPresentingDeleteConfirmation,
					goalCount: 1,
				) {
					deleteGoal(goal)
				}
			}
		}
		.sheet(isPresented: $isPresentingEditForm) {
			NavigationStack {
				GoalFormView(
					mode: .edit(GoalFormData(goal: goal)),
				) { data in
					try goalManager.updateGoal(goal, with: data)
				}
			}
		}
		.sheet(isPresented: $isPresentingProgressUpdateSheet) {
			NavigationStack {
				GoalProgressUpdateView(goal: goal)
			}
		}
		.safeAreaInset(edge: .bottom) {
			GoalDetailBottomView(
				goal: goal,
				openProgressUpdateView: {
					isPresentingProgressUpdateSheet = true
				},
			)
		}
		.goalSaveFailureAlert(failure: $saveFailure)
	}

	private var isShowingReminderIssue: Bool {
		reminderFeedback?.issue(for: goal.id) != nil
	}

	private var goalManager: GoalManager {
		GoalManager(modelContext: modelContext, reminderFeedback: reminderFeedback)
	}

	private func toggleCompletion() {
		do {
			_ = try withAnimation {
				guard try goalManager.toggleCompletion(goal) else {
					return
				}
			}
		} catch {
			saveFailure = .updateProgress
		}
	}

	private func deleteGoal(_ goal: Goal) {
		do {
			try goalManager.deleteGoal(goal)
			dismiss()
		} catch {
			saveFailure = .deleteGoal
		}
	}
}

// MARK: - Previews

#Preview("Outcome") {
	NavigationStack {
		GoalDetailView(
			goal: Goal(
				name: "Climb Mount Kilimanjaro",
				details: "Reach the summit of Mount Kilimanjaro by the end of the year..",
				progress: .outcome(OutcomeProgress()),
			)
		)
	}
}

#Preview("Measurable") {
	NavigationStack {
		GoalDetailView(
			goal: Goal(
				name: "Run a 5K",
				details: "Build up endurance with three runs per week.",
				progress: .measurable(currentValue: 1, targetValue: 5),
			)
		)
	}
}
