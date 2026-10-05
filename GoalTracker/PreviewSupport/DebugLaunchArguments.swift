//
//  DebugLaunchArguments.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/12/26.
//

#if DEBUG

import Foundation

// MARK: - DebugLaunchArguments

enum DebugLaunchArguments {
	static let screenshotData = "-goaltracker.screenshotData"

	static var isUsingScreenshotData: Bool {
		ProcessInfo.processInfo.arguments.contains(screenshotData)
	}
}

#endif
