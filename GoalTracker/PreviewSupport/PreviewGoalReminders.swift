//
//  PreviewGoalReminders.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 10/5/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

#if DEBUG
import SwiftData
import SwiftUI

extension View {
	/// Supplies the same reminder dependencies as navigation, using an isolated preview store.
	@MainActor
	func previewGoalReminders() -> some View {
		let container = GoalPreviewContainer.make(goals: [])
		let coordinator = GoalReminderCoordinator(modelContext: container.mainContext)
		return
			self
			.modelContainer(container)
			.environment(coordinator)
	}
}
#endif
