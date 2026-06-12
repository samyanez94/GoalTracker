//
//  DebugModelContainerFactory.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/12/26.
//

#if DEBUG

import Foundation
import SwiftData

// MARK: - DebugModelContainerFactory

@MainActor
enum DebugModelContainerFactory {
	static func appStoreScreenshotsContainer(referenceDate: Date = Date()) throws -> ModelContainer {
		let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		let data = DebugSeedData.appStoreScreenshots(referenceDate: referenceDate)

		for tag in data.tags {
			container.mainContext.insert(tag)
		}
		for goal in data.goals {
			container.mainContext.insert(goal)
		}
		try container.mainContext.save()

		return container
	}
}

#endif
