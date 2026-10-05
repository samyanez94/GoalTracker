import SwiftUI

/// An actionable banner at the top of the affected goal’s detail content.
struct GoalReminderFeedbackView: View {
	@Environment(\.openURL) private var openURL

	@Environment(\.dynamicTypeSize) private var dynamicTypeSize

	@State private var saveFailure: GoalSaveFailure?

	let coordinator: GoalReminderCoordinator
	let issue: GoalReminderIssue
	let onDisableReminder: () throws -> Void

	var body: some View {
		GoalDetailCard {
			VStack(alignment: .leading) {
				Label {
					Text(.reminderFeedbackTitle)
				} icon: {
					Image(systemName: "exclamationmark.triangle.fill")
						.foregroundStyle(.orange)
				}
				.font(.headline)
				Text(issue.message)
				(dynamicTypeSize.isAccessibilitySize
					? AnyLayout(VStackLayout(alignment: .leading))
					: AnyLayout(HStackLayout())) {
						if coordinator.isRetrying(for: issue.goalId) {
							ProgressView(.reminderFeedbackRetrying)
						} else {
							if issue.isPermissionDenied {
								Button(.reminderFeedbackOpenSettings) {
									if let url = URL(string: "app-settings:") {
										openURL(url)
									}
								}
							} else {
								Button(.reminderFeedbackRetry) {
									Task { await coordinator.retry(for: issue.goalId) }
								}
							}
						}
						Button(.reminderFeedbackDisableReminder, action: disableReminder)
							.disabled(coordinator.isRetrying(for: issue.goalId))
					}
					.buttonStyle(.bordered)
			}
		}
		.goalSaveFailureAlert(failure: $saveFailure)
	}

	private func disableReminder() {
		do {
			try onDisableReminder()
		} catch {
			saveFailure = .updateGoal
		}
	}
}
