//
//  GoalTagSummaryText.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/20/26.
//

import SwiftUI

struct GoalTagSummaryText: View {
	let tags: [Tag]

	var body: some View {
		if !tags.isEmpty {
			Text(summary)
				.font(.subheadline).bold()
				.foregroundStyle(.secondary)
				.accessibilityLabel(accessibilitySummary)
		}
	}

	private var summary: String {
		sortedTagNames
			.map { tagName in "#\(tagName)" }
			.joined(separator: " ")
	}

	private var accessibilitySummary: String {
		let tagNames = sortedTagNames.joined(separator: ", ")
		return sortedTagNames.count == 1 ? "Tag: \(tagNames)" : "Tags: \(tagNames)"
	}

	private var sortedTagNames: [String] {
		sortedTags.map(\.name)
	}

	private var sortedTags: [Tag] {
		tags.sorted { lhs, rhs in
			lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
		}
	}
}
