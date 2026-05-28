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
                Image(systemName: goal.status.iconSystemName)
                    .foregroundStyle(.blue)
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                    if let dueDate = goal.dueDate {
                        Text(GoalDueDateFormatter.string(from: dueDate))
                            .font(.subheadline)
                            .foregroundStyle(isPastDue(dueDate) ? .red : .secondary)
                    }
                    GoalTagSummaryText(tags: goal.tags)
                }
            }
        }
        .contextMenu {
            GoalActionMenuItems(
                isCompleted: goal.isCompleted,
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

    private func isPastDue(_ dueDate: Date) -> Bool {
        !goal.isCompleted
            && Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: Date())
    }
}

#Preview {
    let goals = [
        Goal(
            name: "Run a 5K",
            details: "Build up endurance with three runs per week.",
            dueDate: Calendar.current.date(
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
            dueDate: Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: Date()
            ),
            createdAt: Date(),
            progress: .outcomePending,
        ),
        Goal(
            name: "Travel to Japan",
            details: "Plan and take the trip.",
            createdAt: Date(),
            progress: .outcomeCompleted,
        ),
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
