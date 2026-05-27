//
//  GoalDetailStatusSection.swift
//  GoalTracker
//
//  Created by Codex on 5/24/26.
//

import SwiftUI

struct GoalDetailStatusSection: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)
                .foregroundStyle(.secondary)
            HStack {
                Text(goal.isCompleted ? "Completed" : "Pending")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                Spacer(minLength: 16)
                GoalDetailCircularProgressView(
                    progress: goal.progress.fractionCompleted
                )
                .frame(width: 80, height: 80)
            }
            .padding(.all, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: .rect(cornerRadius: 24, style: .continuous),
            )
        }
    }
}

#Preview("Pending") {
    GoalDetailStatusSection(
        goal: Goal(
            name: "Travel to Japan",
            details: "Plan and take the trip.",
            createdAt: Date(),
            progress: .outcomePending,
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Completed") {
    GoalDetailStatusSection(
        goal: Goal(
            name: "Travel to Japan",
            details: "Plan and take the trip.",
            createdAt: Date(),
            progress: .outcomeCompleted,
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
