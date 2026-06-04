//
//  GoalProgressEventSection.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/4/26.
//

// MARK: - GoalProgressEventSection

struct GoalProgressEventSection: Equatable, Identifiable {
	let id: String
	let title: String
	let events: [GoalProgressEvent]
}
