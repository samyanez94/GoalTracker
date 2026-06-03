//
//  GoalFormTagSelection.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/3/26.
//

/// A tag selected in the goal form, including draft tags that are not persisted until save.
struct GoalFormTagSelection: Identifiable, Hashable {
	var name: String
	var normalizedName: String

	var id: String {
		normalizedName
	}

	init(
		name: String,
		normalizedName: String,
	) {
		self.name = name
		self.normalizedName = normalizedName
	}

	init(tag: Tag) {
		self.init(
			name: tag.name,
			normalizedName: tag.normalizedName,
		)
	}

	init(name: String) {
		let displayName = Tag.sanitizedName(from: name)
		self.init(
			name: displayName,
			normalizedName: Tag.normalizedName(from: displayName),
		)
	}
}
