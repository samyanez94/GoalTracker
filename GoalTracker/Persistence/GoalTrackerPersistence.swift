//
//  GoalTrackerPersistence.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/5/26.
//

import Foundation
import Observation
import SwiftData

// MARK: - GoalTrackerPersistence

/// Loads the app's SwiftData container and preserves failures for recovery UI.
@MainActor
@Observable
final class GoalTrackerPersistence {
	private(set) var state: State

	@ObservationIgnored private let makeContainer: () throws -> ModelContainer

	init(isStoredInMemoryOnly: Bool = false) {
		self.makeContainer = {
			try GoalTrackerModelContainer.make(isStoredInMemoryOnly: isStoredInMemoryOnly)
		}
		state = Self.load(using: makeContainer)
	}

	init(makeContainer: @escaping () throws -> ModelContainer) {
		self.makeContainer = makeContainer
		state = Self.load(using: makeContainer)
	}

	func retry() {
		state = Self.load(using: makeContainer)
	}

	private static func load(using makeContainer: () throws -> ModelContainer) -> State {
		do {
			let container = try makeContainer()
			return .ready(container)
		} catch {
			return .failed(GoalTrackerPersistenceFailure(error: error))
		}
	}

	enum State {
		case ready(ModelContainer)
		case failed(GoalTrackerPersistenceFailure)
	}
}

// MARK: - GoalTrackerPersistenceFailure

struct GoalTrackerPersistenceFailure {
	let message: String
	let diagnosticDetails: String

	init(error: Error) {
		if let localizedError = error as? LocalizedError,
			let errorDescription = localizedError.errorDescription
		{
			message = errorDescription
		} else {
			message = error.localizedDescription
		}
		diagnosticDetails = String(reflecting: error)
	}
}
