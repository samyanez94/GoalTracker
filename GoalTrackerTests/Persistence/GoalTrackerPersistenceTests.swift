//
//  GoalTrackerPersistenceTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 6/5/26.
//

import Foundation
import SwiftData
import Testing

@testable import GoalTracker

@MainActor
struct GoalTrackerPersistenceTests {
	@Test
	func `Container load failure enters recovery state`() {
		let persistence = GoalTrackerPersistence {
			throw TestPersistenceError.failed
		}

		switch persistence.state {
		case .failed(let failure):
			#expect(failure.message == "Test store failed.")
			#expect(failure.diagnosticDetails.contains("TestPersistenceError.failed"))
		case .ready:
			Issue.record("Expected persistence to enter the failure state.")
		}
	}

	@Test
	func `Retry attempts to load the container again`() throws {
		var attemptCount = 0
		let persistence = GoalTrackerPersistence {
			attemptCount += 1
			if attemptCount == 1 {
				throw TestPersistenceError.failed
			}
			return try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
		}

		if case .ready = persistence.state {
			Issue.record("Expected the first load attempt to fail.")
		}

		persistence.retry()

		switch persistence.state {
		case .ready:
			#expect(attemptCount == 2)
		case .failed:
			Issue.record("Expected retry to load the model container.")
		}
	}
}

private enum TestPersistenceError: LocalizedError {
	case failed

	var errorDescription: String? {
		"Test store failed."
	}
}
