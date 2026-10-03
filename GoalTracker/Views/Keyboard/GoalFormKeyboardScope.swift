//
//  GoalFormKeyboardScope.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 10/3/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import SwiftUI

/// Keeps main app commands disabled for the lifetime of a form's presentation container.
private struct GoalFormKeyboardScope: ViewModifier {
	@Environment(\.goalKeyboardState) private var keyboardState

	@State private var isRegistered = false

	func body(content: Content) -> some View {
		content
			.onAppear {
				guard !isRegistered, let keyboardState else { return }
				keyboardState.formDidAppear()
				isRegistered = true
			}
			.onDisappear {
				guard isRegistered else { return }
				keyboardState?.formDidDisappear()
				isRegistered = false
			}
	}
}

extension View {
	/// Attach to a sheet's navigation container so pushed screens retain the same keyboard scope.
	func goalFormKeyboardScope() -> some View {
		modifier(GoalFormKeyboardScope())
	}
}
