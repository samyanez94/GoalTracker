//
//  GoalTrackerApp.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import SwiftData
import SwiftUI

@main
struct GoalTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            GoalTrackerRootView()
        }
        .modelContainer(for: [Goal.self, GoalProgressEntry.self])
    }
}

private struct GoalTrackerRootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var goalStore: GoalStore?

    var body: some View {
        Group {
            if let goalStore {
                GoalListView(goalStore: goalStore)
            } else {
                ProgressView()
                    .task {
                        goalStore = GoalStore(modelContext: modelContext)
                    }
            }
        }
    }
}
