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
  @State private var goalStore = GoalStore()

  var body: some Scene {
    WindowGroup {
      GoalListView(goalStore: goalStore)
    }
    .modelContainer(for: [Goal.self, GoalProgressEntry.self])
  }
}
