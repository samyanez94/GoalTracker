//
//  GoalProgressEvent.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/28/26.
//

import Foundation

/// A timestamped change to a goal's progress value.
nonisolated struct GoalProgressEvent: Codable, Equatable, Identifiable {
	/// A stable identifier used for row identity and event-specific actions.
	var id: UUID
	/// The amount added to or removed from the goal's progress.
	var delta: Double
	/// The time this progress change happened.
	var timestamp: Date

	init(
		id: UUID = UUID(),
		delta: Double,
		timestamp: Date,
	) {
		self.id = id
		self.delta = delta
		self.timestamp = timestamp
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
		delta = try container.decode(Double.self, forKey: .delta)
		timestamp = try container.decode(Date.self, forKey: .timestamp)
	}

	private enum CodingKeys: String, CodingKey {
		case id
		case delta
		case timestamp
	}
}
