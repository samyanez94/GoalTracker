//
//  DueDateSummaryButton.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct DueDateSummaryButton: View {
    let hasDueDate: Bool
    let dueDate: Date
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Due Date")
                    if hasDueDate {
                        Text(GoalDueDateFormatter.string(from: dueDate))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
