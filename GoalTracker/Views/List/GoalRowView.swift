import SwiftData
import SwiftUI

// MARK: - GoalRowView

struct GoalRowView: View {
	@Environment(\.editMode) private var editMode

	@Environment(\.modelContext) private var modelContext

	@State private var isPresentingEditForm = false

	@State private var isPresentingDeleteConfirmation = false

	@State private var saveFailure: GoalSaveFailure?

	let goal: Goal

	var body: some View {
		let isCompleted = goal.isCompleted()
		NavigationLink(value: GoalNavigationDestination.goal(goal.id)) {
			HStack(spacing: 12) {
				if editMode?.wrappedValue.isEditing != true {
					Image(systemName: goal.status().iconSystemName)
						.imageScale(.large)
						.foregroundStyle(statusImageStyle)
						.contentTransition(.symbolEffect(.replace))
						.accessibilityHidden(true)
				}
				VStack(alignment: .leading, spacing: 2) {
					Text(goal.name)
						.foregroundStyle(isCompleted ? .secondary : .primary)
					if let targetDate = goal.targetDate {
						let formattedDate = GoalTargetDateFormatter.string(from: targetDate)
						let isPastTargetDate = goal.isPastTargetDate()
						HStack(spacing: 4) {
							if isPastTargetDate {
								Image(systemName: "exclamationmark.circle.fill")
									.imageScale(.small)
									.accessibilityHidden(true)
							}
							Text(formattedDate)
						}
						.font(.subheadline)
						.foregroundStyle(isPastTargetDate ? .red : .secondary)
						.accessibilityElement(children: .combine)
						.accessibilityLabel(
							targetDateAccessibilityLabel(
								formattedDate: formattedDate,
								isPastTargetDate: isPastTargetDate
							)
						)
					}
					if let recurrence = goal.recurrence {
						Text(recurrence.rowTitle)
							.font(.subheadline)
							.foregroundStyle(.secondary)
							.accessibilityLabel(recurrenceAccessibilityLabel(for: recurrence))
					}
					GoalTagSummaryText(tags: goal.tags ?? [])
				}
			}
			.accessibilityElement(children: .combine)
			.accessibilityValue(goal.status().title)
		}
		.navigationLinkIndicatorVisibility(editMode?.wrappedValue.isEditing != true ? .automatic : .hidden)
		.contextMenu {
			GoalActionMenuContent(
				isCompleted: isCompleted,
				edit: {
					isPresentingEditForm = true
				},
				toggleCompletion: toggleCompletion,
				delete: {
					isPresentingDeleteConfirmation = true
				},
			)
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
		.goalDeleteConfirmationDialog(
			isPresented: $isPresentingDeleteConfirmation,
			goalCount: 1,
			onDelete: deleteGoal,
		)
		.goalSaveFailureAlert(failure: $saveFailure)
	}

	private var goalManager: GoalManager {
		GoalManager(modelContext: modelContext)
	}

	private var statusImageStyle: AnyShapeStyle {
		goal.isCompleted() ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.tertiary)
	}

	private func targetDateAccessibilityLabel(
		formattedDate: String,
		isPastTargetDate: Bool,
	) -> LocalizedStringResource {
		if isPastTargetDate {
			return .goalRowTargetDatePastAccessibilityLabel(formattedDate)
		}
		return .goalRowTargetDateAccessibilityLabel(formattedDate)
	}

	private func recurrenceAccessibilityLabel(for recurrence: GoalRecurrence) -> LocalizedStringResource {
		let rowTitle = String(localized: recurrence.rowTitle)
		return .goalRowRecurrenceAccessibilityLabel(rowTitle)
	}

	private func toggleCompletion() {
		do {
			_ = try withAnimation {
				try goalManager.toggleCompletion(goal)
			}
		} catch {
			saveFailure = .updateProgress
		}
	}

	private func deleteGoal() {
		do {
			_ = try withAnimation {
				try goalManager.deleteGoal(goal)
			}
		} catch {
			saveFailure = .deleteGoal
		}
	}

}

// MARK: - Previews

#Preview {
	let goals = [
		Goal(
			name: "Run a 5K",
			details: "Build up endurance with three runs per week.",
			targetDate: Calendar.current.date(
				byAdding: .day,
				value: 1,
				to: Date()
			),
			progress: .measurable(currentValue: 2, targetValue: 5),
		),
		Goal(
			name: "File taxes",
			details: nil,
			targetDate: Calendar.current.date(
				byAdding: .day,
				value: -1,
				to: Date()
			),
			progress: .outcome(OutcomeProgress()),
		),
		Goal(
			name: "Go climbing",
			details: "Go climbing every month.",
			progress: .outcome(OutcomeProgress.completed(timestamp: Date())),
			recurrence: GoalRecurrence(cadence: .monthly),
		)
	]
	NavigationStack {
		List {
			ForEach(goals) { goal in
				GoalRowView(goal: goal)
			}
		}
	}
}
