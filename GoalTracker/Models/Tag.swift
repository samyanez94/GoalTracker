//
//  Tag.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/19/26.
//

import Foundation
import SwiftData

extension GoalTrackerSchemaV1 {
    /// A reusable label that can be associated with one or more goals.
    @Model
    final class Tag {
        /// A stable app-level identifier for lookups.
        var id: UUID = UUID()
        /// The display name shown to users.
        var name: String = ""
        /// The normalized name used for duplicate detection and lookup.
        var normalizedName: String = ""
        /// The date the tag was created.
        var createdAt: Date = Date()
        /// Goals currently associated with this tag.
        @Relationship(deleteRule: .nullify, inverse: \Goal.tags) var goals: [Goal] = []

        init(
            id: UUID = UUID(),
            name: String,
            normalizedName: String? = nil,
            createdAt: Date = Date(),
        ) {
            let displayName = Self.displayName(from: name)

            self.id = id
            self.name = displayName
            self.normalizedName = normalizedName ?? Self.normalizedName(from: displayName)
            self.createdAt = createdAt
        }

        static func displayName(from name: String) -> String {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedName.starts(with: "#") else {
                return trimmedName
            }
            return String(trimmedName.dropFirst())
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        static func normalizedName(from name: String) -> String {
            displayName(from: name).lowercased()
        }
    }
}

typealias Tag = GoalTrackerSchemaV1.Tag
