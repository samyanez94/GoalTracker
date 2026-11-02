import Foundation
import Testing

@testable import GoalTracker

/// Fixed inputs and independently specified expectations for the 1.2.0 store.
/// Keep this format and its JSON resource unchanged when adding a new schema.
struct V1FixtureManifest: Decodable {
	let sourceCommit: String
	let appVersion: String
	let evaluationDate: Date
	let tags: [V1FixtureTagRecord]
	let goals: [V1FixtureGoalRecord]

	static func load() throws -> Self {
		let url = try resourceURL(name: "goal-tracker-v1", extension: "json")
		return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
	}

	static func resourceURL(name: String, extension fileExtension: String) throws -> URL {
		try #require(Bundle(for: V1FixtureBundle.self).url(forResource: name, withExtension: fileExtension))
	}
}
