//
//  PreviewGoalContainer.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

#if DEBUG
    import SwiftData

    @MainActor
    enum GoalPreviewContainer {
        static func make(goals: [Goal]) -> ModelContainer {
            do {
                let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
                for goal in goals {
                    container.mainContext.insert(goal)
                }
                try container.mainContext.save()
                return container
            } catch {
                preconditionFailure("Failed to create preview model container: \(error)")
            }
        }
    }
#endif
