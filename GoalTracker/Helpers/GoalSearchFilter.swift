//
//  GoalSearchFilter.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/16/26.
//

import Foundation

/// Filters goals by search text across goal names, descriptions, and tags.
struct GoalSearchFilter {
	func filtered(
		_ goals: [Goal],
		searchText: String,
	) -> [Goal] {
		let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmedSearchText.isEmpty else {
			return goals
		}
		return goals.filter { goal in
			goal.name.localizedStandardContains(trimmedSearchText)
				|| goal.details?.localizedStandardContains(trimmedSearchText) == true
				|| (goal.tags ?? [])
					.contains { tag in
						tagMatchesSearchText(tag, searchText: trimmedSearchText)
					}
		}
	}

	private func tagMatchesSearchText(
		_ tag: Tag,
		searchText: String,
	) -> Bool {
		let tagSearchText =
			if searchText.starts(with: "#") {
				Tag.sanitizedName(from: searchText)
			} else {
				searchText
			}
		guard !tagSearchText.isEmpty else {
			return false
		}
		return tag.name.localizedStandardContains(tagSearchText)
	}
}
