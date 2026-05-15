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

    var body: some View {
        ForEach(goals) { goal in
            GoalRowView(
                goal: goal,
                goalManager: goalManager,
            )
        }
    }
}
