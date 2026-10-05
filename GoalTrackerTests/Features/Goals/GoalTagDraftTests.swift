import Testing

@testable import GoalTracker

@MainActor
struct GoalTagDraftTests {
	@Test(arguments: [
		("  # Health  ", "Health", "health"),
		("Morning Walk", "MorningWalk", "morningwalk"),
		(" # ", "", "")
	])
	func `Tag drafts normalize names without picker state`(
		input: String,
		expectedName: String,
		expectedNormalizedName: String
	) {
		let draft = GoalTagDraft(name: input)

		#expect(draft.name == expectedName)
		#expect(draft.normalizedName == expectedNormalizedName)
	}
}
