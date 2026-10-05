//
//  GoalKeyboardEnvironment.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 10/3/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import SwiftUI

extension FocusedValues {
	/// The main app actions exported by the active scene, or `nil` during recovery.
	@Entry var goalKeyboardActions: GoalKeyboardActions?
}

extension EnvironmentValues {
	/// Presentation tracking shared by the sidebar and detail sheets within one scene.
	@Entry var goalKeyboardState: GoalKeyboardState?
}
