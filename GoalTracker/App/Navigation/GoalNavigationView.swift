//
//  GoalNavigationView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 10/3/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import SwiftData
import SwiftUI

/// Owns adaptive navigation and services shared by the list and detail columns.
struct GoalNavigationView: View {
	@Environment(\.modelContext) private var modelContext

	@Environment(\.scenePhase) private var scenePhase

	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	@Query private var goals: [Goal]

	@State private var navigation = GoalNavigationState()

	@State private var reminderCoordinator = GoalReminderCoordinator()

	@State private var keyboardState = GoalKeyboardState()

	@State private var columnVisibility = NavigationSplitViewVisibility.automatic

	private let notificationRouter: GoalNotificationRouter

	init(notificationRouter: GoalNotificationRouter = GoalNotificationRouter()) {
		self.notificationRouter = notificationRouter
	}

	var body: some View {
		NavigationSplitView(columnVisibility: $columnVisibility) {
			GoalListView(
				navigation: navigation,
				notificationRouter: notificationRouter,
				onRevealSidebar: revealSidebar
			)
		} detail: {
			NavigationStack(path: $navigation.detailPath) {
				Group {
					if let goalID = navigation.selectedGoalID {
						if let goal = goals.first(where: { $0.id == goalID }) {
							GoalDetailView(goal: goal)
								.id(goalID)
						} else {
							GoalUnavailableView.goalNotFound()
						}
					} else {
						GoalUnavailableView(
							.goalNavigationSelectGoalTitle,
							systemImage: "target",
							description: .goalNavigationSelectGoalDescription
						)
					}
				}
				.navigationDestination(for: GoalNavigationDestination.self) { destination in
					switch destination {
					case .progressEvents(let goalID):
						if let goal = goals.first(where: { $0.id == goalID }) {
							GoalProgressEventListView(goal: goal)
						} else {
							GoalUnavailableView.goalNotFound()
						}
					}
				}
			}
		}
		.navigationSplitViewStyle(.balanced)
		.environment(\.goalReminderCoordinator, reminderCoordinator)
		.environment(\.goalKeyboardState, keyboardState)
		.task(
			id: GoalReminderRefreshTrigger(
				isActive: scenePhase == .active,
				states: goals.map { GoalReminderSyncState(goal: $0) }
			)
		) {
			guard scenePhase == .active else {
				return
			}
			await reminderCoordinator.reconcileReminders(modelContext: modelContext)
		}
	}

	private func revealSidebar() {
		columnVisibility = .all
		if horizontalSizeClass == .compact {
			navigation.selectedGoalID = nil
		}
	}
}

// MARK: - Previews

#if DEBUG

#Preview("No goals") {
	let container = GoalPreviewContainer.make(
		goals: [],
	)
	GoalNavigationView().modelContainer(container)
}

#Preview("Three goals") {
	let container = GoalPreviewContainer.make(
		goals: [
			Goal(
				name: "Travel to Switzerland",
				progress: .outcome(OutcomeProgress.completed(timestamp: Date())),
			),
			Goal(
				name: "Climb Mount Kilimanjaro",
				progress: .outcome(OutcomeProgress()),
			),
			Goal(
				name: "Run 10 marathons",
				progress: .measurable(
					currentValue: 2,
					targetValue: 10
				),
			)
		],
	)
	GoalNavigationView().modelContainer(container)
}

#endif
