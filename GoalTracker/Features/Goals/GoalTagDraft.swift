//
//  GoalTagDraft.swift
//  GoalTracker
//

/// A tag to associate with a saved goal, including tags that do not exist yet.
/// Selection and other picker state belong to the form rather than service input.
struct GoalTagDraft: Hashable {
	let name: String
	let normalizedName: String

	init(name: String) {
		let displayName = Tag.sanitizedName(from: name)
		self.name = displayName
		normalizedName = Tag.normalizedName(from: displayName)
	}

	init(tag: Tag) {
		self.init(name: tag.name)
	}
}
