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
        }
    }

    private var summary: String {
        sortedTags
            .map { tag in "#\(tag.name)" }
            .joined(separator: " ")
    }

    private var sortedTags: [Tag] {
        tags.sorted { lhs, rhs in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}
