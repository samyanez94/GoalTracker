//
//  TagSelectionView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/19/26.
//

import SwiftUI

struct TagSelectionView: View {

    @State private var tagNames = sampleTagNames

    @State private var selectedTagNames: [String] = []

    @State private var newTagName = ""

    @FocusState private var newTagFieldIsFocused: Bool

    var body: some View {
        Form {
            if !tagNames.isEmpty {
                Section {
                    TagFlowLayout {
                        ForEach(tagNames, id: \.self) { tagName in
                            TagChip(
                                name: tagName,
                                isSelected: isSelected(tagName),
                            ) {
                                toggleSelection(of: tagName)
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
    }

    private func isSelected(_ tagName: String) -> Bool {
        let normalizedName = Tag.normalizedName(from: tagName)
        return selectedTagNames.contains {
            Tag.normalizedName(from: $0) == normalizedName
        }
    }

    private func toggleSelection(of tagName: String) {
        let normalizedName = Tag.normalizedName(from: tagName)
        if let index = selectedTagNames.firstIndex(where: {
            Tag.normalizedName(from: $0) == normalizedName
        }) {
            selectedTagNames.remove(at: index)
        } else {
            selectedTagNames.append(tagName)
        }
    }

    private func addTag() {
        let trimmedTagName = Tag.trimmedName(from: newTagName)
        guard !trimmedTagName.isEmpty else {
            return
        }
        let normalizedName = Tag.normalizedName(from: trimmedTagName)
        if let existingTagName = tagNames.first(where: {
            Tag.normalizedName(from: $0) == normalizedName
        }) {
            if !isSelected(existingTagName) {
                selectedTagNames.append(existingTagName)
            }
            newTagName = ""
            newTagFieldIsFocused = true
            return
        }
        tagNames.append(trimmedTagName)
        selectedTagNames.append(trimmedTagName)
        newTagName = ""
        newTagFieldIsFocused = true
    }
}

extension TagSelectionView {

    private static let sampleTagNames = [
        "YOLO",
        "Fun",
        "2026",
    ]
}

#Preview {
    NavigationStack {
        TagSelectionView()
    }
}
