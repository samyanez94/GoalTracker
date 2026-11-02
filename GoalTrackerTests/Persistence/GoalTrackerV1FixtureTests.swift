import CryptoKit
import Foundation
import SwiftData
import Testing

@testable import GoalTracker

@MainActor
struct GoalTrackerV1FixtureTests {
	@Test
	func `Committed V1 store preserves the production baseline across reopen`() throws {
		let directory = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
		defer { try? FileManager.default.removeItem(at: directory) }
		let storeURL = directory.appending(path: "baseline.store")
		let baselineURL = try V1FixtureManifest.resourceURL(name: "goal-tracker-v1", extension: "store")
		let originalData = try Data(contentsOf: baselineURL)
		let checksum = SHA256.hash(data: originalData)
			.map { byte in
				let hex = String(byte, radix: 16)
				return hex.count == 1 ? "0" + hex : hex
			}
			.joined()
		#expect(
			checksum
				== "52aa38cd5b50fcc0dc478ab1de486fe6946573c08ca829b79770727ba82f9013"
		)
		try FileManager.default.copyItem(at: baselineURL, to: storeURL)
		let manifest = try V1FixtureManifest.load()
		#expect(manifest.appVersion == "1.2.0")
		#expect(manifest.sourceCommit == "5d15dab40648e7618c0f6b190e100b5bce107444")
		for _ in 0..<2 {
			try autoreleasepool {
				let container = try V1FixtureStore.open(at: storeURL)
				try verify(container, against: manifest)
			}
		}
		#expect(try Data(contentsOf: baselineURL) == originalData)
	}

	private func verify(_ container: ModelContainer, against manifest: V1FixtureManifest) throws {
		let context = ModelContext(container)
		let goals = try context.fetch(FetchDescriptor<GoalTrackerSchemaV1.Goal>())
		let tags = try context.fetch(FetchDescriptor<GoalTrackerSchemaV1.Tag>())
		#expect(Set(goals.map(\.id)) == Set(manifest.goals.map(\.id)))
		#expect(goals.count == manifest.goals.count)
		#expect(tags.count == manifest.tags.count)
		for record in manifest.goals {
			let goal = try #require(goals.first { $0.id == record.id })
			#expect(goal.name == record.name)
			#expect(goal.details == record.details)
			#expect(goal.createdAt == record.createdAt)
			#expect(goal.targetDate == record.targetDate)
			#expect(goal.reminder == record.reminder)
			#expect(goal.recurrence == record.recurrence)
			#expect(goal.progress == record.progress)
			#expect(goal.progress.events.map(\.id) == record.expectedEventIDs)
			#expect(goal.progress.events.map(\.delta) == record.expectedEventDeltas)
			#expect(goal.progress.events.map(\.timestamp) == record.expectedEventTimestamps)
			#expect(goal.progress.measurableProgress?.targetValue == record.expectedTargetValue)
			#expect(goal.progress.measurableProgress?.step == record.expectedStep)
			#expect(goal.progress.measurableProgress?.unit?.id == record.expectedUnitID)
			if record.expectedUnitID == "custom.fixture" {
				let unit = try #require(goal.progress.measurableProgress?.unit)
				#expect(unit.category == .custom)
				#expect(unit.title == "Practice blocks")
				#expect(unit.abbreviatedTitle == "blk")
				#expect(unit.prefix == "~")
				#expect(unit.suffix == "blk")
			}
			#expect(Set((goal.tags ?? []).map(\.id)) == Set(record.tagIDs))
			#expect(goal.currentProgressValue(at: manifest.evaluationDate, calendar: ModelTestSupport.calendar) == record.expectedValue)
			#expect(goal.isCompleted(at: manifest.evaluationDate, calendar: ModelTestSupport.calendar) == record.expectedCompleted)
			#expect(goal.currentStreak(at: manifest.evaluationDate, calendar: ModelTestSupport.calendar) == record.expectedStreak)
		}
		for record in manifest.tags {
			let tag = try #require(tags.first { $0.id == record.id })
			#expect(tag.name == record.name)
			#expect(tag.normalizedName == record.normalizedName)
			#expect(tag.createdAt == record.createdAt)
			let expectedGoalIDs = Set(manifest.goals.filter { $0.tagIDs.contains(record.id) }.map(\.id))
			#expect(Set((tag.goals ?? []).map(\.id)) == expectedGoalIDs)
		}
	}
}
