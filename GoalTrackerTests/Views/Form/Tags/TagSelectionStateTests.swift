//
//  TagSelectionStateTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 6/9/26.
//

import Testing

@testable import GoalTracker

@MainActor
struct TagSelectionStateTests {
	@Test
	func `Creating a draft tag selects it and makes it visible`() {
		var state = TagSelectionState(
			persistedTags: [],
			tagSelections: [],
		)

		let didAddTag = state.addTag(named: "# Health ")

		#expect(didAddTag)
		#expect(state.tagSelections.map(\.name) == ["Health"])
		#expect(
			state.tagSelections.allSatisfy { tagSelection in
				tagSelection.isSelected
			}
		)
		#expect(state.visibleTags.map(\.name) == ["Health"])
		#expect(
			state.visibleTags.allSatisfy { tagSelection in
				tagSelection.isSelected
			}
		)
	}

	@Test
	func `Deselecting a draft tag leaves it visible when state is rebuilt`() throws {
		var state = TagSelectionState(
			persistedTags: [],
			tagSelections: [],
		)
		state.addTag(named: "Health")
		let tag = try #require(state.visibleTags.first)

		state.toggleSelection(of: tag)
		let rebuiltState = TagSelectionState(
			persistedTags: [],
			tagSelections: state.tagSelections,
		)

		#expect(state.tagSelections.map(\.isSelected) == [false])
		#expect(rebuiltState.visibleTags.map(\.name) == ["Health"])
		#expect(rebuiltState.visibleTags.map(\.isSelected) == [false])
	}

	@Test
	func `Readding a deselected draft tag selects it without duplicating it`() throws {
		var state = TagSelectionState(
			persistedTags: [],
			tagSelections: [],
		)
		state.addTag(named: "Health")
		let tag = try #require(state.visibleTags.first)
		state.toggleSelection(of: tag)

		state.addTag(named: "health")

		#expect(state.tagSelections.map(\.normalizedName) == ["health"])
		#expect(state.tagSelections.map(\.isSelected) == [true])
		#expect(state.visibleTags.map(\.normalizedName) == ["health"])
		#expect(state.visibleTags.map(\.isSelected) == [true])
	}

	@Test
	func `Adding a tag matching a persisted tag selects it without duplicating it`() {
		let persistedTag = GoalFormTagSelection(name: "Health", isSelected: false)
		var state = TagSelectionState(
			persistedTags: [persistedTag],
			tagSelections: [],
		)

		state.addTag(named: "health")

		#expect(state.tagSelections.map(\.normalizedName) == ["health"])
		#expect(state.tagSelections.map(\.isSelected) == [true])
		#expect(state.visibleTags.map(\.normalizedName) == ["health"])
		#expect(state.visibleTags.map(\.isSelected) == [true])
	}

	@Test
	func `Selected tags stay visible when absent from persisted tags`() {
		let selectedTag = GoalFormTagSelection(name: "Health")
		let state = TagSelectionState(
			persistedTags: [],
			tagSelections: [selectedTag],
		)

		#expect(state.visibleTags == [selectedTag])
		#expect(state.isSelected(selectedTag))
	}
}
