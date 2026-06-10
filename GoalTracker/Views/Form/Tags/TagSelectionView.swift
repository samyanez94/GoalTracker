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

	@Binding private var tagSelections: [GoalFormTagSelection]

	@Query(sort: [SortDescriptor<Tag>(\.normalizedName)]) private var availableTags: [Tag]

	@State private var newTagName = ""

	@FocusState private var newTagFieldIsFocused: Bool

	init(tagSelections: Binding<[GoalFormTagSelection]>) {
		_tagSelections = tagSelections
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
				TextField(.tagSelectionAddNewTagField, text: $newTagName)
					.focused($newTagFieldIsFocused)
					.submitLabel(.done)
					.textInputAutocapitalization(.words)
					.onChange(of: newTagName) { _, updatedName in
						sanitizeNewTagName(updatedName)
					}
					.onSubmit(addTag)
			}
		}
		.navigationTitle(.commonTags)
		.navigationBarTitleDisplayMode(.inline)
	}

	private var hasAvailableTags: Bool {
		!mergedTags.isEmpty
	}

	private var mergedTags: [GoalFormTagSelection] {
		tagSelectionState.visibleTags
	}

	private func isSelected(_ tag: GoalFormTagSelection) -> Bool {
		tagSelectionState.isSelected(tag)
	}

	private func toggleSelection(of tag: GoalFormTagSelection) {
		var state = tagSelectionState
		state.toggleSelection(of: tag)
		withAnimation {
			apply(state)
		}
	}

	private func addTag() {
		var state = tagSelectionState
		guard state.addTag(named: newTagName) else {
			return
		}
		apply(state)
		resetNewTagField()
	}

	private func sanitizeNewTagName(_ name: String) {
		let sanitizedName = Tag.sanitizedName(from: name)
		guard sanitizedName != name else {
			return
		}
		newTagName = sanitizedName
	}

	private func resetNewTagField() {
		newTagName = ""
		newTagFieldIsFocused = true
	}

	private var tagSelectionState: TagSelectionState {
		TagSelectionState(
			persistedTags: availableTags.map { tag in
				GoalFormTagSelection(tag: tag, isSelected: false)
			},
			tagSelections: tagSelections,
		)
	}

	private func apply(_ state: TagSelectionState) {
		tagSelections = state.tagSelections
	}
}

// MARK: - Previews

#Preview {
	NavigationStack {
		TagSelectionView(tagSelections: .constant([]))
	}
	.modelContainer(GoalPreviewContainer.make(goals: []))
}
