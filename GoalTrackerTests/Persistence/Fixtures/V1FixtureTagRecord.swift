import Foundation

@testable import GoalTracker

struct V1FixtureTagRecord: Decodable {
	let id: UUID
	let name: String
	let normalizedName: String
	let createdAt: Date
}
