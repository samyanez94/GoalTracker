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

	@Environment(\.modelContext) private var modelContext

	@Binding private var selectedTags: [Tag]

	@Query(sort: [SortDescriptor<Tag>(\.normalizedName)]) private var availableTags: [Tag]

	@State private var isEditing = false

	@State private var saveFailure: GoalSaveFailure?

	@State private var newTagName = ""

	@FocusState private var newTagFieldIsFocused: Bool

	init(selectedTags: Binding<[Tag]>) {
		_selectedTags = selectedTags
	}

	var body: some View {
		Form {
			if hasAvailableTags {
				Section {
					TagFlowLayout {
						ForEach(availableTags, id: \.id) { tag in
							EditableTagChip(
								tag: tag,
								isSelected: isSelected(tag),
								isEditing: isEditing,
								toggleSelection: toggleSelection,
								deleteTag: deleteTag,
							)
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
					.onChange(of: newTagFieldIsFocused) { _, isFocused in
						handleNewTagFieldFocusChanged(isFocused)
					}
					.onSubmit(addTag)
			}
		}
		.navigationTitle("Tags")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			if canShowEditButton {
				ToolbarItem(placement: .topBarTrailing) {
					Button(isEditing ? "Done" : "Edit", action: toggleEditMode)
				}
			}
		}
		.onDisappear {
			try? GoalManager(modelContext: modelContext).deleteUnusedTags(excluding: selectedTags)
		}
		.onChange(of: availableTags.isEmpty) { _, tagsAreEmpty in
			handleAvailableTagsEmptyChanged(tagsAreEmpty)
		}
		.goalSaveFailureAlert(failure: $saveFailure)
	}

	private var hasAvailableTags: Bool {
		!availableTags.isEmpty
	}

	private var canShowEditButton: Bool {
		hasAvailableTags || isEditing
	}

	private func isSelected(_ tag: Tag) -> Bool {
		selectedTags.contains { selectedTag in
			selectedTag.normalizedName == tag.normalizedName
		}
	}

	private func toggleSelection(of tag: Tag) {
		guard !isEditing else {
			return
		}
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
		let tag =
			existingTag(named: sanitizedTagName) ?? createAvailableTag(named: sanitizedTagName)
		select(tag)
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

	private func createAvailableTag(named name: String) -> Tag {
		let tag = Tag(name: name)
		modelContext.insert(tag)
		return tag
	}

	private func toggleEditMode() {
		isEditing.toggle()
		if isEditing {
			newTagFieldIsFocused = false
		}
	}

	private func handleNewTagFieldFocusChanged(_ isFocused: Bool) {
		if isFocused {
			isEditing = false
		}
	}

	private func handleAvailableTagsEmptyChanged(_ tagsAreEmpty: Bool) {
		if tagsAreEmpty {
			isEditing = false
		}
	}

	private func deleteTag(_ tag: Tag) {
		let tagWasSelected = isSelected(tag)
		removeSelection(of: tag)
		do {
			try GoalManager(modelContext: modelContext).deleteTag(tag)
		} catch {
			if tagWasSelected {
				select(tag)
			}
			saveFailure = .deleteTag
		}
	}

	private func select(_ tag: Tag) {
		guard !isSelected(tag) else {
			return
		}
		selectedTags.append(tag)
	}

	private func removeSelection(of tag: Tag) {
		selectedTags.removeAll { selectedTag in
			selectedTag.normalizedName == tag.normalizedName
		}
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
