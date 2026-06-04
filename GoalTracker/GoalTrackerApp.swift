//
//  GoalTrackerApp.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation
import SwiftData
import SwiftUI
import UserNotifications

@main
struct GoalTrackerApp: App {
	private let modelContainer: ModelContainer

	@State private var notificationRouter: GoalNotificationRouter

	init() {
		do {
			modelContainer = try GoalTrackerModelContainer.make(
				isStoredInMemoryOnly: Self.isRunningTests
			)
		} catch {
			fatalError("Failed to create model container: \(error)")
		}
		let notificationRouter = GoalNotificationRouter()
		UNUserNotificationCenter.current().delegate = notificationRouter
		_notificationRouter = State(initialValue: notificationRouter)
	}

	var body: some Scene {
		WindowGroup {
			GoalListView(notificationRouter: notificationRouter)
		}
		.modelContainer(modelContainer)
	}

	private static var isRunningTests: Bool {
		ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
	}
}
