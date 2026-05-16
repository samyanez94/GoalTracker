//
//  GoalListBottomToolbar.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/16/26.
//

import SwiftUI

struct GoalListBottomToolbar: ToolbarContent {
    let onAddGoal: () -> Void

    var body: some ToolbarContent {
        DefaultToolbarItem(kind: .search, placement: .bottomBar)
        ToolbarSpacer(.flexible, placement: .bottomBar)
        ToolbarItem(placement: .bottomBar) {
            Button("Add Goal", systemImage: "plus", action: onAddGoal)
                .buttonStyle(.glassProminent)
        }
    }
}
