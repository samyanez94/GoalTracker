//
//  GoalDetailProgressSection.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/23/26.
//

import SwiftUI

// MARK: - GoalDetailProgressSection

struct GoalDetailProgressSection: View {
    
	let goalId: UUID

	let recurrence: GoalRecurrence?

	let progress: MeasurableProgress

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			NavigationLink(value: GoalNavigationDestination.progressEvents(goalId)) {
				HStack(alignment: .firstTextBaseline, spacing: 4) {
					Text("Progress")
						.font(.headline)
					Image(systemName: "chevron.right")
						.font(.headline.weight(.semibold))
						.imageScale(.small)
						.accessibilityHidden(true)
					Spacer()
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.contentShape(.rect)
			}
			.buttonStyle(.plain)
			.foregroundStyle(.secondary)
			HStack {
				VStack(alignment: .leading, spacing: 4) {
					Text(progressTitle)
						.font(.title2.bold())
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
			}
			.padding(.all, 16)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(
				Color(.secondarySystemGroupedBackground),
				in: .rect(cornerRadius: 24, style: .continuous),
			)
		}
	}

	private var fractionCompleted: Double {
		let fraction: Double
		if let currentPeriod {
			fraction = progress.fractionCompleted(in: currentPeriod)
		} else {
			fraction = progress.fractionCompleted
		}
		return min(max(fraction, 0), 1)
	}

	private var progressTitle: String {
		let currentValue = formattedNumber(
			currentProgressValue,
			for: progress
		)
		let targetValue = formattedNumber(
			progress.targetValue,
			for: progress
		)
		if unitText.isEmpty {
			return "\(currentValue)/\(targetValue)"
		} else {
			return "\(currentValue)/\(targetValue) \(unitText)"
		}
	}

	private var progressSubtitle: String {
		guard !isCompleted else {
			return "Completed"
		}
		let remainingValue = max(progress.targetValue - currentProgressValue, 0)
		let remainingText = formattedNumber(
			remainingValue,
			for: progress
		)
		guard !unitText.isEmpty else {
			return "\(remainingText) more to go"
		}
		return "\(remainingText) \(unitText) more to go"
	}

	private func formattedNumber(_ value: Double, for progress: MeasurableProgress) -> String {
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

	private var currentPeriod: DateInterval? {
		recurrence?.period(containing: Date())
	}

	private var currentProgressValue: Double {
		if let currentPeriod {
			progress.currentValue(in: currentPeriod)
		} else {
			progress.currentValue
		}
	}

	private var isCompleted: Bool {
		if let currentPeriod {
			progress.isCompleted(in: currentPeriod)
		} else {
			progress.isCompleted
		}
	}
}

// MARK: - Previews

#Preview("In Progress") {
	GoalDetailProgressSection(
		goalId: UUID(),
		recurrence: nil,
		progress: .init(
			currentValue: 8,
			targetValue: 10,
			unit: .custom(
				title: "Marathons",
				abbreviatedTitle: "marathons",
			),
		)
	)
	.padding()
	.background(Color(.systemGroupedBackground))
}

#Preview("Completed") {
	GoalDetailProgressSection(
		goalId: UUID(),
		recurrence: nil,
		progress: .init(
			currentValue: 2_500,
			targetValue: 2_500,
			unit: .dollars,
		)
	)
	.padding()
	.background(Color(.systemGroupedBackground))
}

#Preview("Decimal Progress") {
	GoalDetailProgressSection(
		goalId: UUID(),
		recurrence: nil,
		progress: .init(
			currentValue: 2.5,
			targetValue: 5,
			unit: .kilometers,
		)
	)
	.padding()
	.background(Color(.systemGroupedBackground))
}
