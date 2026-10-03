//
//  GoalKeyboardActions.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 10/3/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

/// Actions available to keyboard commands in the active scene. Empty actions disable them in forms.
struct GoalKeyboardActions {
	/// Opens the create-goal form; `nil` disables the New command.
	var addGoal: (() -> Void)?

	/// Reveals and focuses goal search; `nil` disables the Find command.
	var searchGoals: (() -> Void)?
}
