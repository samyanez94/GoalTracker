//
//  GoalNavigationStateTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 10/3/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalNavigationStateTests {
	@Test
	func `Selecting another goal returns the detail stack to its root`() {
		let navigation = GoalNavigationState()
		let firstGoalID = UUID()
		let secondGoalID = UUID()
		navigation.selectedGoalID = firstGoalID
		navigation.detailPath = [.progressEvents(firstGoalID)]

		navigation.selectedGoalID = secondGoalID

		#expect(navigation.selectedGoalID == secondGoalID)
		#expect(navigation.detailPath.isEmpty)
	}

	@Test
	func `Clearing selection removes history for the previous goal`() {
		let navigation = GoalNavigationState()
		let goalID = UUID()
		navigation.selectedGoalID = goalID
		navigation.detailPath = [.progressEvents(goalID)]

		navigation.selectedGoalID = nil

		#expect(navigation.selectedGoalID == nil)
		#expect(navigation.detailPath.isEmpty)
	}

	@Test
	func `Selecting the same goal preserves its progress history`() {
		let navigation = GoalNavigationState()
		let goalID = UUID()
		navigation.selectedGoalID = goalID
		navigation.detailPath = [.progressEvents(goalID)]

		navigation.selectedGoalID = goalID

		#expect(navigation.detailPath == [.progressEvents(goalID)])
	}

	@Test
	func `Entering bulk editing preserves the displayed goal and history`() {
		let navigation = GoalNavigationState()
		let goalID = UUID()
		navigation.selectedGoalID = goalID
		navigation.detailPath = [.progressEvents(goalID)]

		navigation.updateSidebarSelection(nil, isEditing: true)
		navigation.updateSidebarSelection(UUID(), isEditing: true)

		#expect(navigation.selectedGoalID == goalID)
		#expect(navigation.detailPath == [.progressEvents(goalID)])
	}

	@Test
	func `Sidebar navigation resumes after bulk editing`() {
		let navigation = GoalNavigationState()
		let previousGoalID = UUID()
		let nextGoalID = UUID()
		navigation.selectedGoalID = previousGoalID
		navigation.detailPath = [.progressEvents(previousGoalID)]

		navigation.updateSidebarSelection(nextGoalID, isEditing: false)

		#expect(navigation.selectedGoalID == nextGoalID)
		#expect(navigation.detailPath.isEmpty)
	}

	@Test
	func `Navigation state is independent for each window`() {
		let firstWindow = GoalNavigationState()
		let secondWindow = GoalNavigationState()
		let goalID = UUID()
		firstWindow.selectedGoalID = goalID
		firstWindow.detailPath = [.progressEvents(goalID)]

		#expect(secondWindow.selectedGoalID == nil)
		#expect(secondWindow.detailPath.isEmpty)
	}
}
