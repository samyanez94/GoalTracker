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
	var isSelected: Bool

	var id: String {
		normalizedName
	}

	init(
		name: String,
		normalizedName: String,
		isSelected: Bool = true,
	) {
		self.name = name
		self.normalizedName = normalizedName
		self.isSelected = isSelected
	}

	init(tag: Tag, isSelected: Bool = true) {
		self.init(
			name: tag.name,
			normalizedName: tag.normalizedName,
			isSelected: isSelected,
		)
	}

	init(name: String, isSelected: Bool = true) {
		let displayName = Tag.sanitizedName(from: name)
		self.init(
			name: displayName,
			normalizedName: Tag.normalizedName(from: displayName),
			isSelected: isSelected,
		)
	}
}
