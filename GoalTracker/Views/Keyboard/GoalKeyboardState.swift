//
//  GoalKeyboardState.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 10/3/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import Observation

/// Tracks presented forms so scene commands cannot interrupt a modal editing session.
@MainActor
@Observable
final class GoalKeyboardState {
	private var presentedFormCount = 0

	/// Remains true until every presented form container has disappeared.
	var isPresentingForm: Bool { presentedFormCount > 0 }

	func formDidAppear() {
		presentedFormCount += 1
	}

	func formDidDisappear() {
		presentedFormCount = max(0, presentedFormCount - 1)
	}
}
