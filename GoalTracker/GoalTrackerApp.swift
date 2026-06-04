//
//  GoalTrackerApp.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation
import SwiftData
import SwiftUI

@main
struct GoalTrackerApp: App {
	private let modelContainer: ModelContainer

	init() {
		do {
			modelContainer = try GoalTrackerModelContainer.make(
				isStoredInMemoryOnly: Self.isRunningTests
			)
		} catch {
			fatalError("Failed to create model container: \(error)")
		}
	}

	var body: some Scene {
		WindowGroup {
			GoalListView()
		}
		.modelContainer(modelContainer)
	}

	private static var isRunningTests: Bool {
		ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
	}
}
