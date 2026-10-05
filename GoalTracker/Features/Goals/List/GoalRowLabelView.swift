//
//  GoalRowLabelView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 10/3/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import SwiftUI

struct GoalRowLabelView: View {
	@Environment(\.editMode) private var editMode

	@Environment(GoalReminderCoordinator.self) private var reminderCoordinator

	let goal: Goal

	var body: some View {
		let isCompleted = goal.isCompleted()
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
			if reminderCoordinator.issue(for: goal.id) != nil {
				Spacer()
				Image(systemName: "exclamationmark.triangle.fill")
					.foregroundStyle(.orange)
					.accessibilityLabel(Text(.reminderFeedbackTitle))
			}
		}
		.accessibilityElement(children: .combine)
		.accessibilityValue(goal.status().title)
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

}
