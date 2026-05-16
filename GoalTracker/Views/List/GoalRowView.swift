import SwiftData
import SwiftUI

struct GoalRowView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var saveFailure: GoalSaveFailure?

    let goal: Goal

    var body: some View {
        NavigationLink(value: goal) {
            HStack(spacing: 12) {
                CircularGoalProgressView(
                    progress: goal.progress.fractionCompleted,
                )
                .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .foregroundStyle(goal.isCompleted ? .secondary : .primary)
                    if let dueDate = goal.dueDate {
                        Text(GoalDueDateFormatter.string(from: dueDate))
                            .font(.subheadline)
                            .foregroundStyle(isPastDue(dueDate) ? .red : .secondary)
                    }
                }
            }
        }
        .contextMenu {
            Button {
                toggleCompletion()
            } label: {
                Label(
                    goal.isCompleted ? "Mark as Pending" : "Mark as Completed",
                    systemImage: goal.isCompleted ? "circle" : "checkmark.circle",
                )
            }
            Button(role: .destructive) {
                deleteGoal()
            } label: {
                Label("Delete", systemImage: "trash")
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
