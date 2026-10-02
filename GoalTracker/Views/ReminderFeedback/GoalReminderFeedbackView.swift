import SwiftData
import SwiftUI

/// An actionable banner at the top of the affected goal’s detail content.
struct GoalReminderFeedbackView: View {
	@Environment(\.openURL) private var openURL

	@Environment(\.scenePhase) private var scenePhase

	@Environment(\.dynamicTypeSize) private var dynamicTypeSize

	@State private var saveFailure: GoalSaveFailure?

	@State private var isReturningFromSettings = false

	let feedback: GoalReminderFeedback
	let issue: GoalReminderIssue
	let modelContext: ModelContext

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
						if feedback.isRetrying {
							ProgressView(.reminderFeedbackRetrying)
						} else {
							if issue.isPermissionDenied {
								Button(.reminderFeedbackOpenSettings) {
									if let url = URL(string: "app-settings:") {
										isReturningFromSettings = true
										openURL(url)
									}
								}
							} else {
								Button(.reminderFeedbackRetry) {
									Task { await feedback.retry(modelContext: modelContext) }
								}
							}
						}
						Button(.reminderFeedbackDisableReminder, action: disableReminder)
							.disabled(feedback.isRetrying)
					}
					.buttonStyle(.bordered)
			}
		}
		.onChange(of: scenePhase) { _, phase in
			guard phase == .active, isReturningFromSettings else { return }
			isReturningFromSettings = false
			Task { await feedback.retry(modelContext: modelContext) }
		}
		.goalSaveFailureAlert(failure: $saveFailure)
	}

	private func disableReminder() {
		do {
			try feedback.disableReminder(for: issue.goalId, modelContext: modelContext)
		} catch {
			saveFailure = .updateGoal
		}
	}
}
