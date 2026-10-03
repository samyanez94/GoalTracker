//
//  GoalKeyboardCommands.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 10/3/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import SwiftUI

/// Routes app shortcuts to the active scene, including when its sidebar is collapsed.
struct GoalKeyboardCommands: Commands {
	@FocusedValue(\.goalKeyboardActions) private var actions

	var body: some Commands {
		CommandGroup(replacing: .newItem) {
			Button(.goalListAddGoal, systemImage: "plus") {
				actions?.addGoal?()
			}
			.keyboardShortcut("n", modifiers: .command)
			.disabled(actions?.addGoal == nil)
			Button(.goalListSearchPrompt, systemImage: "magnifyingglass") {
				actions?.searchGoals?()
			}
			.keyboardShortcut("f", modifiers: .command)
			.disabled(actions?.searchGoals == nil)
		}
	}
}
