//
//  TagSelectionState.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/9/26.
//

import Foundation

/// Coordinates visible, draft, and selected tags for the tag picker screen.
struct TagSelectionState {
	var persistedTags: [GoalFormTagSelection]
	var tagSelections: [GoalFormTagSelection]

	var visibleTags: [GoalFormTagSelection] {
		var tagsByNormalizedName: [String: GoalFormTagSelection] = [:]
		for tag in persistedTags {
			tagsByNormalizedName[tag.normalizedName] = tag
		}
		for tag in tagSelections {
			if var persistedTag = tagsByNormalizedName[tag.normalizedName] {
				persistedTag.isSelected = tag.isSelected
				tagsByNormalizedName[tag.normalizedName] = persistedTag
			} else {
				tagsByNormalizedName[tag.normalizedName] = tag
			}
		}
		return tagsByNormalizedName.values.sorted { lhs, rhs in
			lhs.normalizedName.localizedStandardCompare(rhs.normalizedName) == .orderedAscending
		}
	}

	func isSelected(_ tag: GoalFormTagSelection) -> Bool {
		visibleTag(matching: tag.normalizedName)?.isSelected ?? tag.isSelected
	}

	mutating func toggleSelection(of tag: GoalFormTagSelection) {
		if let index = tagSelections.firstIndex(where: { selectedTag in
			selectedTag.normalizedName == tag.normalizedName
		}) {
			tagSelections[index].isSelected.toggle()
		} else {
			select(tag)
		}
	}

	@discardableResult
	mutating func addTag(named name: String) -> Bool {
		let sanitizedTagName = Tag.sanitizedName(from: name)
		guard !sanitizedTagName.isEmpty else {
			return false
		}
		if let tag = visibleTag(named: sanitizedTagName) {
			select(tag)
		} else {
			let draftTag = GoalFormTagSelection(name: sanitizedTagName)
			select(draftTag)
		}
		return true
	}

	private func visibleTag(named name: String) -> GoalFormTagSelection? {
		let normalizedName = Tag.normalizedName(from: name)
		return visibleTag(matching: normalizedName)
	}

	private func visibleTag(matching normalizedName: String) -> GoalFormTagSelection? {
		return visibleTags.first { tag in
			tag.normalizedName == normalizedName
		}
	}

	private mutating func select(_ tag: GoalFormTagSelection) {
		if let index = tagSelections.firstIndex(where: { selectedTag in
			selectedTag.normalizedName == tag.normalizedName
		}) {
			tagSelections[index].isSelected = true
			return
		}
		tagSelections.append(
			GoalFormTagSelection(
				name: tag.name,
				normalizedName: tag.normalizedName,
				isSelected: true,
			)
		)
	}
}
