import Foundation

@testable import GoalTracker

struct V1FixtureGoalRecord: Decodable {
	let id: UUID
	let name: String
	let details: String?
	let createdAt: Date
	let targetDate: Date?
	let reminder: GoalReminder?
	let progress: GoalProgress
	let recurrence: GoalRecurrence?
	let tagIDs: [UUID]
	// Independent projections avoid validating a changed production decoder against itself.
	let expectedEventIDs: [UUID]
	let expectedEventDeltas: [Double]
	let expectedEventTimestamps: [Date]
	let expectedTargetValue: Double?
	let expectedStep: Double?
	let expectedUnitID: String?
	let expectedValue: Double
	let expectedCompleted: Bool
	let expectedStreak: Int?
}
