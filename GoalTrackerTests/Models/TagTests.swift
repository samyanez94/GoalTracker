//
//  TagTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/19/26.
//

import Foundation
import SwiftData
import Testing

@testable import GoalTracker

@MainActor
struct TagTests {
	@Test(
		arguments: [
			(" Health ", "Health", "health"),
			("#Health", "Health", "health"),
			("#  Health  ", "Health", "health"),
			("Home Gym", "HomeGym", "homegym"),
			("Focus\tWork", "FocusWork", "focuswork"),
			("Morning\nRoutine", "MorningRoutine", "morningroutine")
		],
	)
	func `Tag initializer stores display name and normalized name`(
		input: String,
		expectedName: String,
		expectedNormalizedName: String,
	) {
		let tag = Tag(name: input)

		#expect(tag.name == expectedName)
		#expect(tag.normalizedName == expectedNormalizedName)
	}

	@Test
	func `Goal tag relationship persists in model container`() throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let goal = Goal(
			name: "Run a 5K",
			details: nil,
			createdAt: Date(timeIntervalSinceReferenceDate: 0),
			progress: .outcomePending,
		)
		let tag = Tag(
			name: "#Health",
			createdAt: Date(timeIntervalSinceReferenceDate: 1),
		)

		goal.tags = [tag]
		container.mainContext.insert(goal)
		container.mainContext.insert(tag)
		try container.mainContext.save()

		let fetchedGoal = try #require(
			try container.mainContext.fetch(FetchDescriptor<Goal>()).first,
		)
		let fetchedTag = try #require(fetchedGoal.tags.first)

		#expect(fetchedTag.name == "Health")
		#expect(fetchedTag.normalizedName == "health")
		#expect(fetchedTag.goals.map(\.id) == [goal.id])
	}

	@Test
	func `Alphabetical sort descriptor sorts tags by normalized name`() throws {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		for tag in [
			Tag(name: "Zebra"),
			Tag(name: "apple"),
			Tag(name: "Banana")
		] {
			container.mainContext.insert(tag)
		}
		try container.mainContext.save()

		let tags = try container.mainContext.fetch(
			FetchDescriptor<GoalTrackerSchemaV1.Tag>(
				sortBy: [SortDescriptor<GoalTrackerSchemaV1.Tag>(\.normalizedName)],
			),
		)

		#expect(tags.map(\.name) == ["apple", "Banana", "Zebra"])
	}
}
