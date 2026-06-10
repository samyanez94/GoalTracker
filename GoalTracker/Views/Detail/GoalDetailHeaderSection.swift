//
//  GoalDetailHeaderSection.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/23/26.
//

import SwiftUI

struct GoalDetailHeaderSection: View {
	let goal: Goal

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(goal.name)
				.font(.largeTitle.bold())
				.foregroundStyle(.primary)
				.accessibilityAddTraits(.isHeader)
			if let recurrence = goal.recurrence {
				Label(recurrence.detailTitle, systemImage: "repeat.circle.fill")
					.font(.body.bold())
			}
			if let details = goal.details,
				!details.isEmpty
			{
				Text(details)
					.font(.body)
					.foregroundStyle(.secondary)
			}
			if let targetDate = goal.targetDate {
				let text = targetDateText(for: targetDate)
				let isPastTargetDate = goal.isPastTargetDate()
				HStack(spacing: 4) {
					if isPastTargetDate {
						Image(systemName: "exclamationmark.circle.fill")
							.imageScale(.small)
							.accessibilityHidden(true)
					}
					Text(text)
				}
				.font(.body.bold())
				.foregroundStyle(isPastTargetDate ? .red : .secondary)
				.accessibilityElement(children: .combine)
			}
			if goal.tags?.isEmpty == false {
				TagFlowLayout {
					ForEach(sortedTags, id: \.id) { tag in
						GoalDetailTagChip(tag: tag)
					}
				}
				.padding(.vertical, 4)
			}
		}
	}

	private var sortedTags: [Tag] {
		(goal.tags ?? [])
			.sorted { lhs, rhs in
				lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
			}
	}

	private func targetDateText(for targetDate: Date) -> LocalizedStringResource {
		if Calendar.current.isDateInToday(targetDate) {
			return .detailTargetDateToday
		}
		if Calendar.current.isDateInTomorrow(targetDate) {
			return .detailTargetDateTomorrow
		}
		let formattedDate = targetDate.formatted(date: .long, time: .omitted)
		return .detailTargetDateDate(formattedDate)
	}
}
