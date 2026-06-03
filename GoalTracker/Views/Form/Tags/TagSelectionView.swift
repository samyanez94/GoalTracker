//
//  TagSelectionView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/19/26.
//

import SwiftData
import SwiftUI

// MARK: - TagSelectionView

struct TagSelectionView: View {

	@Binding private var selectedTags: [GoalFormTagSelection]

	@Query(sort: [SortDescriptor<Tag>(\.normalizedName)]) private var availableTags: [Tag]

	@State private var newTagName = ""

	@FocusState private var newTagFieldIsFocused: Bool

	init(selectedTags: Binding<[GoalFormTagSelection]>) {
		_selectedTags = selectedTags
	}

	var body: some View {
		Form {
			if hasAvailableTags {
				Section {
					TagFlowLayout {
						ForEach(mergedTags) { tag in
							TagChip(
								name: tag.name,
								isSelected: isSelected(tag),
							) {
								toggleSelection(of: tag)
							}
						}
					}
				}
			}
			Section {
				TextField("Add New Tag...", text: $newTagName)
					.focused($newTagFieldIsFocused)
					.submitLabel(.done)
					.textInputAutocapitalization(.words)
					.onChange(of: newTagName) { _, updatedName in
						sanitizeNewTagName(updatedName)
					}
					.onSubmit(addTag)
			}
		}
		.navigationTitle("Tags")
		.navigationBarTitleDisplayMode(.inline)
	}

	private var hasAvailableTags: Bool {
		!mergedTags.isEmpty
	}

	private var mergedTags: [GoalFormTagSelection] {
		var tagsByNormalizedName: [String: GoalFormTagSelection] = [:]
		for tag in availableTags {
			tagsByNormalizedName[tag.normalizedName] = GoalFormTagSelection(tag: tag)
		}
		for tag in selectedTags where tagsByNormalizedName[tag.normalizedName] == nil {
			tagsByNormalizedName[tag.normalizedName] = tag
		}
		return tagsByNormalizedName.values.sorted { lhs, rhs in
			lhs.normalizedName.localizedStandardCompare(rhs.normalizedName) == .orderedAscending
		}
	}

	private func isSelected(_ tag: GoalFormTagSelection) -> Bool {
		selectedTags.contains { selectedTag in
			selectedTag.normalizedName == tag.normalizedName
		}
	}

	private func toggleSelection(of tag: GoalFormTagSelection) {
		if let index = selectedTags.firstIndex(where: { selectedTag in
			selectedTag.normalizedName == tag.normalizedName
		}) {
			selectedTags.remove(at: index)
		} else {
			select(tag)
		}
	}

	private func addTag() {
		let sanitizedTagName = Tag.sanitizedName(from: newTagName)
		guard !sanitizedTagName.isEmpty else {
			return
		}
		if let tag = existingTag(named: sanitizedTagName) {
			select(GoalFormTagSelection(tag: tag))
		} else {
			select(GoalFormTagSelection(name: sanitizedTagName))
		}
		resetNewTagField()
	}

	private func sanitizeNewTagName(_ name: String) {
		let sanitizedName = Tag.sanitizedName(from: name)
		guard sanitizedName != name else {
			return
		}
		newTagName = sanitizedName
	}

	private func existingTag(named name: String) -> Tag? {
		let normalizedName = Tag.normalizedName(from: name)
		return availableTags.first { tag in
			tag.normalizedName == normalizedName
		}
	}

	private func select(_ tag: GoalFormTagSelection) {
		guard !isSelected(tag) else {
			return
		}
		selectedTags.append(tag)
	}

	private func resetNewTagField() {
		newTagName = ""
		newTagFieldIsFocused = true
	}
}

// MARK: - Previews

#Preview {
	NavigationStack {
		TagSelectionView(selectedTags: .constant([]))
	}
	.modelContainer(GoalPreviewContainer.make(goals: []))
}
