//
//  EditableTagChip.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/20/26.
//

import SwiftUI

struct EditableTagChip: View {
    let tag: Tag
    let isSelected: Bool
    let isEditing: Bool
    let toggleSelection: (Tag) -> Void
    let deleteTag: (Tag) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            TagChip(
                name: tag.name,
                isSelected: isSelected,
                isSelectionEnabled: !isEditing,
            ) {
                toggleSelection(tag)
            }
            .padding([.top, .leading], isEditing ? 6 : 0)
            if isEditing {
                Button("Delete Tag", systemImage: "xmark.circle.fill") {
                    withAnimation {
                        deleteTag(tag)
                    }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.white, Color(.systemGray))
                .symbolRenderingMode(.palette)
            }
        }
    }
}
