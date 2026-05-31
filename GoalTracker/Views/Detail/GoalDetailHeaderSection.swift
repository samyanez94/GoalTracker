//
//  GoalDetailHeaderSection.swift
//  GoalTracker
//
//  Created by Codex on 5/23/26.
//

import SwiftUI

struct GoalDetailHeaderSection: View {
	let goal: Goal

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(goal.name).font(.largeTitle.bold()).foregroundStyle(.primary)
			if let recurrence = goal.recurrence {
				Label(recurrence.detailTitle, systemImage: "repeat.circle.fill").font(.body.bold())
			}
			if let details = goal.details, !details.isEmpty {
				Text(details).font(.body).foregroundStyle(.secondary)
			}
			if let dueDate = goal.dueDate {
				let text = dueDateText(for: dueDate)
				Text(text).font(.body.bold())
					.foregroundStyle(isPastDue(dueDate) ? .red : .secondary)
			}
			if !goal.tags.isEmpty {
				TagFlowLayout {
					ForEach(sortedTags, id: \.id) { tag in GoalDetailTagChip(tag: tag) }
				}
				.padding(.vertical, 4)
			}
		}
	}

	private var sortedTags: [Tag] {
		goal.tags.sorted { lhs, rhs in
			lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
		}
	}

	private func dueDateText(for dueDate: Date) -> String {
		if Calendar.current.isDateInToday(dueDate) { return "Complete by today" }
		if Calendar.current.isDateInTomorrow(dueDate) { return "Complete by tomorrow" }
		return "Complete by \(dueDate.formatted(date: .long, time: .omitted))"
	}

	private func isPastDue(_ dueDate: Date) -> Bool {
		Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: Date())
	}
}
