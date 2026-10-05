//
//  GoalKeyboardStateTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 10/3/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import Testing

@testable import GoalTracker

@MainActor
struct GoalKeyboardStateTests {
	@Test
	func `Main commands resume after a form closes`() {
		let state = GoalKeyboardState()
		#expect(!state.isPresentingForm)
		state.formDidAppear()
		#expect(state.isPresentingForm)
		state.formDidDisappear()
		#expect(!state.isPresentingForm)
	}

	@Test
	func `Overlapping presentations keep commands blocked until both close`() {
		let state = GoalKeyboardState()
		state.formDidAppear()
		state.formDidAppear()
		state.formDidDisappear()
		#expect(state.isPresentingForm)
		state.formDidDisappear()
		#expect(!state.isPresentingForm)
	}

	@Test
	func `An unmatched dismissal does not affect the next presentation`() {
		let state = GoalKeyboardState()
		state.formDidDisappear()
		state.formDidAppear()
		#expect(state.isPresentingForm)
	}

	@Test
	func `Presentation tracking is independent for each scene`() {
		let firstScene = GoalKeyboardState()
		let secondScene = GoalKeyboardState()
		firstScene.formDidAppear()
		#expect(!secondScene.isPresentingForm)
	}
}
