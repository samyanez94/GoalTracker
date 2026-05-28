//
//  GoalDetailProgressSection.swift
//  GoalTracker
//
//  Created by Codex on 5/23/26.
//

import SwiftUI

struct GoalDetailProgressSection: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress")
                .font(.headline)
                .foregroundStyle(.secondary)
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(fractionCompleted, format: .percent.precision(.fractionLength(0)))
                        .font(.title.bold())
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText(value: fractionCompleted))
                    Text(progressSubtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                GoalDetailCircularProgressView(
                    progress: fractionCompleted
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

    private var progress: GoalProgress {
        goal.progress
    }

    private var fractionCompleted: Double {
        min(max(progress.fractionCompleted, 0), 1)
    }

    private var progressSubtitle: String {
        let currentValue = formattedNumber(progress.currentValue, for: progress)
        let targetValue = formattedNumber(progress.targetValue, for: progress)
        if unitText.isEmpty {
            return "\(currentValue)/\(targetValue)"
        } else {
            return "\(currentValue)/\(targetValue) \(unitText)"
        }
    }

    private func formattedNumber(_ value: Double, for progress: GoalProgress) -> String {
        guard let prefix = progress.unit?.prefix else {
            return formattedNumber(value)
        }
        return "\(prefix)\(formattedNumber(value))"
    }

    private func formattedNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return Int(value).formatted()
        }
        return value.formatted()
    }

    private var unitText: String {
        guard let unit = progress.unit else {
            return ""
        }
        return unit.suffix ?? (unit.prefix == nil ? unit.abbreviatedTitle : "")
    }
}

#Preview("In Progress") {
    GoalDetailProgressSection(
        goal: Goal(
            name: "Run 10 marathons",
            details: "Build endurance across the year.",
            createdAt: Date(),
            progress: .measurable(
                currentValue: 8,
                targetValue: 10,
                unit: .custom(
                    title: "Marathons",
                    abbreviatedTitle: "marathons",
                ),
            ),
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Completed") {
    GoalDetailProgressSection(
        goal: Goal(
            name: "Save for a trip",
            details: "Set aside money for travel.",
            createdAt: Date(),
            progress: .measurable(
                currentValue: 2_500,
                targetValue: 2_500,
                unit: .dollars,
            ),
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Decimal Progress") {
    GoalDetailProgressSection(
        goal: Goal(
            name: "Run a 5K",
            details: "Build up distance each week.",
            createdAt: Date(),
            progress: .measurable(
                currentValue: 2.5,
                targetValue: 5,
                unit: .kilometers,
            ),
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
