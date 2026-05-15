//
//  GoalSectionView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct GoalSectionView: View {
    let title: String

    let goals: [Goal]

    @Binding var isExpanded: Bool

    var body: some View {
        if !goals.isEmpty {
            Section(isExpanded: $isExpanded) {
                ForEach(goals) { goal in
                    GoalRowView(goal: goal)
                }
            } header: {
                CollapsibleSectionHeader(
                    title: title,
                    isExpanded: $isExpanded,
                )
            }
        }
    }
}
