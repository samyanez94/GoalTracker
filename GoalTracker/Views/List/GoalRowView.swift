import SwiftData
import SwiftUI

struct GoalRowView: View {
	@Environment(\.editMode) private var editMode

	@Environment(\.modelContext) private var modelContext

	@State private var isPresentingEditForm = false

	@State private var isPresentingDeleteConfirmation = false

	@State private var saveFailure: GoalSaveFailure?

	let goal: Goal

	var body: some View {
		NavigationLink(value: goal) {
			HStack(spacing: 12) {
				if editMode?.wrappedValue.isEditing != true {
					Image(systemName: goal.status().iconSystemName)
						.imageScale(.large)
						.foregroundStyle(statusImageStyle)
						.contentTransition(.symbolEffect(.replace))
				}
				VStack(alignment: .leading, spacing: 2) {
					Text(goal.name)
						.foregroundStyle(goal.isCompleted() ? .secondary : .primary)
					if let targetDate = goal.targetDate {
						Text(GoalTargetDateFormatter.string(from: targetDate))
							.font(.subheadline)
							.foregroundStyle(goal.isPastTargetDate() ? .red : .secondary)
					}
					if let recurrence = goal.recurrence {
						Text(recurrence.rowTitle)
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
					GoalTagSummaryText(tags: goal.tags)
				}
			}
		}
		.contextMenu {
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
		.sheet(isPresented: $isPresentingEditForm) {
			NavigationStack {
				GoalFormView(
					mode: .edit(GoalFormData(goal: goal)),
				) { data in
					try goalManager.updateGoal(goal, with: data)
				}
			}
		}
		.swipeActions {
			Button(role: .destructive) {
				deleteGoal()
			} label: {
				Label("Delete", systemImage: "trash")
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
		goal.isCompleted() ? AnyShapeStyle(.blue) : AnyShapeStyle(.tertiary)
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
