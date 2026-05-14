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
            GoalListView()
        }
        .modelContainer(for: [Goal.self, GoalProgressEntry.self])
    }
}
