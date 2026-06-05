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
	@State private var persistence: GoalTrackerPersistence

	@State private var notificationRouter: GoalNotificationRouter

	init() {
		_persistence = State(
			initialValue: GoalTrackerPersistence(isStoredInMemoryOnly: Self.isRunningTests)
		)
		let notificationRouter = GoalNotificationRouter()
		UNUserNotificationCenter.current().delegate = notificationRouter
		_notificationRouter = State(initialValue: notificationRouter)
	}

	var body: some Scene {
		WindowGroup {
			switch persistence.state {
			case .ready(let modelContainer):
				GoalListView(notificationRouter: notificationRouter)
					.modelContainer(modelContainer)
			case .failed(let failure):
				GoalPersistenceRecoveryView(
					failure: failure,
					retry: persistence.retry,
				)
			}
		}
	}

	private static var isRunningTests: Bool {
		ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
	}
}
