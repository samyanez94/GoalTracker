//
//  TagChip.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/19/26.
//

import SwiftUI

struct TagChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("#\(name)")
                .font(.subheadline.bold())
                .foregroundStyle(isSelected ? .white : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? .blue : Color(.secondarySystemBackground))
                .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}
