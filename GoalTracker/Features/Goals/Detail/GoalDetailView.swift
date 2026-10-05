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

	private static let maximumContentWidth: CGFloat = 640

	@Environment(\.dismiss) private var dismiss

	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	@Environment(\.modelContext) private var modelContext

	@Environment(\.goalReminderCoordinator) private var reminderCoordinator

	@State private var isPresentingEditForm = false

	@State private var isPresentingDeleteConfirmation = false

	@State private var isPresentingProgressUpdateSheet = false

	@State private var saveFailure: GoalSaveFailure?

	let goal: Goal

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 24) {
				if let reminderCoordinator,
					let issue = reminderCoordinator.issue(for: goal.id)
				{
					GoalReminderFeedbackView(
						coordinator: reminderCoordinator,
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
			.frame(maxWidth: Self.maximumContentWidth)
			.frame(maxWidth: .infinity)
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
					mode: .edit(GoalDraft(goal: goal)),
				) { data in
					try goalService.updateGoal(goal, with: data)
				}
			}
			.presentationSizing(.form)
			.goalFormKeyboardScope()
		}
		.sheet(isPresented: $isPresentingProgressUpdateSheet) {
			NavigationStack {
				GoalProgressUpdateView(goal: goal)
			}
			.presentationSizing(.form)
			.goalFormKeyboardScope()
		}
		.safeAreaBar(edge: .bottom) {
			GoalDetailBottomView(
				goal: goal,
				openProgressUpdateView: {
					isPresentingProgressUpdateSheet = true
				},
			)
			.frame(maxWidth: Self.maximumContentWidth)
			.frame(maxWidth: .infinity)
			.safeAreaPadding(.horizontal)
		}
		.goalSaveFailureAlert(failure: $saveFailure)
	}

	private var isShowingReminderIssue: Bool {
		reminderCoordinator?.issue(for: goal.id) != nil
	}

	private var goalService: GoalService {
		GoalService(modelContext: modelContext, reminderCoordinator: reminderCoordinator)
	}

	private func toggleCompletion() {
		do {
			_ = try withAnimation {
				guard try goalService.toggleCompletion(goal) else {
					return
				}
			}
		} catch {
			saveFailure = .updateProgress
		}
	}

	private func deleteGoal(_ goal: Goal) {
		do {
			try goalService.deleteGoal(goal)
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
