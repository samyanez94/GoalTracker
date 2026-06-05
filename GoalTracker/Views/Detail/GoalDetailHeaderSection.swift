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
				Text(text)
					.font(.body.bold())
					.foregroundStyle(goal.isPastTargetDate() ? .red : .secondary)
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
		(goal.tags ?? []).sorted { lhs, rhs in
			lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
		}
	}

	private func targetDateText(for targetDate: Date) -> String {
		if Calendar.current.isDateInToday(targetDate) {
			return "Complete by today"
		}
		if Calendar.current.isDateInTomorrow(targetDate) {
			return "Complete by tomorrow"
		}
		return "Complete by \(targetDate.formatted(date: .long, time: .omitted))"
	}

}
