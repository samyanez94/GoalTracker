import SwiftData
import SwiftUI

struct GoalRowView: View {
	@Environment(\.modelContext) private var modelContext

	@State private var isPresentingEditForm = false

	@State private var saveFailure: GoalSaveFailure?

	let goal: Goal

	var body: some View {
		NavigationLink(value: goal) {
			HStack(spacing: 12) {
				Image(systemName: goal.status().iconSystemName)
					.font(.title2)
					.foregroundStyle(goal.isCompleted() ? Color.blue : Color.secondary)
					.contentTransition(.symbolEffect(.replace))
					.accessibilityHidden(true)
				VStack(alignment: .leading, spacing: 2) {
					Text(goal.name)
						.foregroundStyle(goal.isCompleted() ? .secondary : .primary)
					if let targetDate = goal.targetDate {
						Text(GoalTargetDateFormatter.string(from: targetDate))
							.font(.subheadline)
							.foregroundStyle(isPastTargetDate(targetDate) ? .red : .secondary)
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
				delete: deleteGoal,
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
		.goalSaveFailureAlert(failure: $saveFailure)
	}

	private var goalManager: GoalManager {
		GoalManager(modelContext: modelContext)
	}

	private func toggleCompletion() {
		do {
			try goalManager.toggleCompletion(goal)
		} catch {
			saveFailure = .updateProgress
		}
	}

	private func deleteGoal() {
		do {
			try goalManager.deleteGoal(goal)
		} catch {
			saveFailure = .deleteGoal
		}
	}

	private func isPastTargetDate(_ targetDate: Date) -> Bool {
		!goal.isCompleted()
			&& Calendar.current.startOfDay(for: targetDate) < Calendar.current.startOfDay(for: Date())
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
			createdAt: Date(),
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
			createdAt: Date(),
			progress: .outcome(OutcomeProgress()),
		),
		Goal(
			name: "Travel to Japan",
			details: "Plan and take the trip.",
			createdAt: Date(),
			progress: .outcome(OutcomeProgress.completed(timestamp: Date())),
			recurrence: GoalRecurrence(cadence: .monthly),
		)
	]
	NavigationStack {
		List {
			ForEach(goals) { goal in
				GoalRowView(
					goal: goal,
				)
			}
		}
	}
}
