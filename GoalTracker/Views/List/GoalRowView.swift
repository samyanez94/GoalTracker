import SwiftData
import SwiftUI

struct GoalRowView: View {
    let goal: Goal

    let goalManager: GoalManager

    var body: some View {
        NavigationLink(value: goal.id) {
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
        .swipeActions {
            Button(role: .destructive) {
                goalManager.deleteGoal(goal)
            } label: {
                Label("Delete", systemImage: "trash")
            }
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
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            createdAt: Date(),
            progress: .measurable(currentValue: 2, targetValue: 5),
        ),
        Goal(
            name: "File taxes",
            details: nil,
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
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
    let container = GoalPreviewContainer.make(
        goals: [
            goals[0],
            goals[1],
            goals[2],
        ],
    )
    let goalManager = GoalManager(modelContext: container.mainContext)

    NavigationStack {
        List {
            ForEach(goals) { goal in
                GoalRowView(
                    goal: goal,
                    goalManager: goalManager,
                )
            }
        }
    }
    .modelContainer(container)
}
