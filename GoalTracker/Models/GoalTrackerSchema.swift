//
//  GoalTrackerSchema.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import SwiftData

/// The first persisted SwiftData schema for GoalTracker.
///
/// Add future schema versions instead of editing this baseline after the app has
/// user data that must be migrated.
enum GoalTrackerSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Goal.self,
            GoalProgressEntry.self,
        ]
    }
}

/// Describes how GoalTracker's SwiftData schema evolves over time.
///
/// Version 1 is the initial baseline, so there are no migration stages yet.
enum GoalTrackerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            GoalTrackerSchemaV1.self
        ]
    }

    static var stages: [MigrationStage] {
        []
    }
}

/// Creates SwiftData containers using the app's versioned schema.
enum GoalTrackerModelContainer {
    @MainActor
    static func make(isStoredInMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: GoalTrackerSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: GoalTrackerMigrationPlan.self,
            configurations: [configuration],
        )
    }
}
