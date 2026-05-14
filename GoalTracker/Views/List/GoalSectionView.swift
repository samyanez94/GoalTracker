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
    let goalManager: GoalManager
    @Binding var sortMode: GoalSortMode
    let onMove: (IndexSet, Int, GoalSortMode) -> Void

    var body: some View {
        if !goals.isEmpty {
            Section(isExpanded: $isExpanded) {
                GoalRowsView(
                    goals: goals,
                    goalManager: goalManager,
                    sortMode: $sortMode,
                    onMove: onMove,
                )
            } header: {
                CollapsibleSectionHeader(
                    title: title,
                    isExpanded: $isExpanded,
                )
            }
        }
    }
}
