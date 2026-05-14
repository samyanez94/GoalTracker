//
//  GoalRowsView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct GoalRowsView: View {
    let goals: [Goal]
    let goalManager: GoalManager
    @Binding var sortMode: GoalSortMode
    let onMove: (IndexSet, Int, GoalSortMode) -> Void

    var body: some View {
        ForEach(goals) { goal in
            GoalRowView(
                goal: goal,
                goalManager: goalManager,
            )
        }
        .onMove { source, destination in
            defer {
                sortMode = .manual
            }
            onMove(source, destination, sortMode)
        }
    }
}
