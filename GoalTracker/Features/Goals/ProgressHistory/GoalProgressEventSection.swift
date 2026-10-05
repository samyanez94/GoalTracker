//
//  GoalProgressEventSection.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/4/26.
//

import Foundation

// MARK: - GoalProgressEventSection

struct GoalProgressEventSection: Equatable, Identifiable {
	let id: String
	let title: String
	let events: [GoalProgressEvent]

	init(
		id: String,
		title: String,
		events: [GoalProgressEvent],
	) {
		self.id = id
		self.title = title
		self.events = events
	}

	init(
		id: String,
		title: LocalizedStringResource,
		events: [GoalProgressEvent],
	) {
		self.init(
			id: id,
			title: String(localized: title),
			events: events,
		)
	}
}
