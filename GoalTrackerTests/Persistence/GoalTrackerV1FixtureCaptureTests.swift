import Foundation
import SwiftData
import Testing

@testable import GoalTracker

@MainActor
struct GoalTrackerV1FixtureCaptureTests {
	@Test(.enabled(if: ProcessInfo.processInfo.environment["GOALTRACKER_CAPTURE_V1"] == "1"))
	func `Capture V1 fixture for explicit baseline maintenance`() throws {
		let directory = URL.documentsDirectory.appending(path: "V1FixtureCapture", directoryHint: .isDirectory)
		// Refuse to overwrite a previous capture. Normal tests never generate their own baseline.
		try #require(FileManager.default.fileExists(atPath: directory.path) == false)
		try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
		let url = directory.appending(path: "goal-tracker-v1.store")
		let manifest = try V1FixtureManifest.load()
		try autoreleasepool {
			try V1FixtureStore.generate(at: url, manifest: manifest)
		}
		try autoreleasepool {
			let container = try V1FixtureStore.open(at: url)
			let context = ModelContext(container)
			let goals = try context.fetch(FetchDescriptor<GoalTrackerSchemaV1.Goal>())
			#expect(goals.count == manifest.goals.count)
			for record in manifest.goals {
				let goal = try #require(goals.first { $0.id == record.id })
				#expect(goal.progress == record.progress)
			}
		}
		print("V1 fixture capture: \(directory.path)")
	}
}
