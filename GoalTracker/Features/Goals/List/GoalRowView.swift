import SwiftData
import SwiftUI

// MARK: - GoalRowView

struct GoalRowView: View {
	@Environment(\.editMode) private var editMode

	@Environment(\.modelContext) private var modelContext

	@Environment(\.goalReminderCoordinator) private var reminderCoordinator

	@State private var isPresentingEditForm = false

	@State private var isPresentingDeleteConfirmation = false

	@State private var saveFailure: GoalSaveFailure?

	let goal: Goal

	var body: some View {
		let isCompleted = goal.isCompleted()
		Group {
			if editMode?.wrappedValue.isEditing == true {
				GoalRowLabelView(goal: goal)
			} else {
				NavigationLink(value: goal.id) {
					GoalRowLabelView(goal: goal)
				}
			}
		}
		.tag(goal.id)
		.swipeActions {
			Button(.commonDelete, systemImage: "trash", role: .destructive, action: deleteGoal)
		}
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
					mode: .edit(GoalDraft(goal: goal)),
				) { data in
					try goalService.updateGoal(goal, with: data)
				}
			}
			.presentationSizing(.form)
			.goalFormKeyboardScope()
		}
		.goalDeleteConfirmationDialog(
			isPresented: $isPresentingDeleteConfirmation,
			goalCount: 1,
			onDelete: deleteGoal,
		)
		.goalSaveFailureAlert(failure: $saveFailure)
	}

	private var goalService: GoalService {
		GoalService(modelContext: modelContext, reminderCoordinator: reminderCoordinator)
	}

	private func toggleCompletion() {
		do {
			_ = try withAnimation {
				try goalService.toggleCompletion(goal)
			}
		} catch {
			saveFailure = .updateProgress
		}
	}

	private func deleteGoal() {
		do {
			_ = try withAnimation {
				try goalService.deleteGoal(goal)
			}
		} catch {
			saveFailure = .deleteGoal
		}
	}

}

// MARK: - Previews

#if DEBUG

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
	GoalNavigationView().modelContainer(GoalPreviewContainer.make(goals: goals))
}

#endif
