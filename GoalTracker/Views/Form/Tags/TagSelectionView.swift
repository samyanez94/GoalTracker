//
//  TagSelectionView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/19/26.
//

import SwiftData
import SwiftUI

struct TagSelectionView: View {

    @Environment(\.modelContext) private var modelContext

    @Binding private var selectedTags: [Tag]

    @Query(sort: [SortDescriptor<Tag>(\.normalizedName)]) private var availableTags: [Tag]

    @State private var newTagName = ""

    @FocusState private var newTagFieldIsFocused: Bool

    init(selectedTags: Binding<[Tag]>) {
        _selectedTags = selectedTags
    }

    var body: some View {
        Form {
            if !availableTags.isEmpty {
                Section {
                    TagFlowLayout {
                        ForEach(availableTags, id: \.normalizedName) { tag in
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
                    .onSubmit(addTag)
            }
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            try? GoalManager(modelContext: modelContext).deleteUnusedTags(excluding: selectedTags)
        }
    }

    private func isSelected(_ tag: Tag) -> Bool {
        selectedTags.contains { selectedTag in
            selectedTag.normalizedName == tag.normalizedName
        }
    }

    private func toggleSelection(of tag: Tag) {
        if let index = selectedTags.firstIndex(where: { selectedTag in
            selectedTag.normalizedName == tag.normalizedName
        }) {
            selectedTags.remove(at: index)
        } else {
            select(tag)
        }
    }

    private func addTag() {
        let trimmedTagName = Tag.trimmedName(from: newTagName)
        guard !trimmedTagName.isEmpty else {
            return
        }
        let tag = existingTag(named: trimmedTagName) ?? createAvailableTag(named: trimmedTagName)
        select(tag)
        resetNewTagField()
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

    private func select(_ tag: Tag) {
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

#Preview {
    NavigationStack {
        TagSelectionView(selectedTags: .constant([]))
    }
    .modelContainer(GoalPreviewContainer.make(goals: []))
}
