import Foundation
import SwiftData

@testable import GoalTracker

@MainActor
enum V1FixtureStore {
	static func open(at url: URL) throws -> ModelContainer {
		let schema = Schema(versionedSchema: GoalTrackerSchemaV1.self)
		let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
		return try ModelContainer(
			for: schema,
			// This helper opens the frozen V1 baseline, not the app's evolving migration path.
			configurations: [configuration],
		)
	}

	/// Used only to capture the baseline, never as a substitute for opening the committed store.
	static func generate(at url: URL, manifest: V1FixtureManifest) throws {
		let container = try open(at: url)
		let context = ModelContext(container)
		context.autosaveEnabled = false
		var tagsByID: [UUID: GoalTrackerSchemaV1.Tag] = [:]
		for record in manifest.tags {
			let tag = GoalTrackerSchemaV1.Tag(
				id: record.id,
				name: record.name,
				normalizedName: record.normalizedName,
				createdAt: record.createdAt,
			)
			context.insert(tag)
			tagsByID[record.id] = tag
		}
		for record in manifest.goals {
			let goal = GoalTrackerSchemaV1.Goal(
				id: record.id,
				name: record.name,
				details: record.details,
				targetDate: record.targetDate,
				reminder: record.reminder,
				createdAt: record.createdAt,
				progress: record.progress,
				recurrence: record.recurrence,
			)
			goal.tags = record.tagIDs.compactMap { tagsByID[$0] }
			context.insert(goal)
		}
		try context.save()
	}
}
