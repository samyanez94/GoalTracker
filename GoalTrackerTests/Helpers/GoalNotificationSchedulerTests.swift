//
//  GoalNotificationSchedulerTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/21/26.
//

import Foundation
import Testing
import UserNotifications

@testable import GoalTracker

// MARK: - GoalNotificationSchedulerTests

@MainActor
struct GoalNotificationSchedulerTests {
	@Test
	func `Requesting authorization asks notification center when status is undetermined`()
		async throws
	{
		let notificationCenter = FakeNotificationCenter(status: .notDetermined)
		let scheduler = makeScheduler(notificationCenter: notificationCenter)

		let isAuthorized = try await scheduler.requestAuthorizationIfNeeded()

		#expect(isAuthorized)
		#expect(notificationCenter.requestedAuthorizationOptions == [.alert, .sound])
	}

	@Test
	func `Requesting authorization returns false when denied`() async throws {
		let notificationCenter = FakeNotificationCenter(status: .denied)
		let scheduler = makeScheduler(notificationCenter: notificationCenter)

		let isAuthorized = try await scheduler.requestAuthorizationIfNeeded()

		#expect(isAuthorized == false)
		#expect(notificationCenter.requestedAuthorizationOptions == nil)
	}

	@Test
	func `Syncing eligible reminders requests authorization before scheduling`() async throws {
		let notificationCenter = FakeNotificationCenter(status: .notDetermined)
		let scheduler = makeScheduler(notificationCenter: notificationCenter)
		let goal = makeGoal(
			targetDate: date(year: 2026, month: 5, day: 21),
			reminder: GoalReminder(),
		)

		let didSchedule = try await scheduler.syncReminder(
			for: goal,
			requestsAuthorization: true,
		)

		#expect(didSchedule)
		#expect(notificationCenter.requestedAuthorizationOptions == [.alert, .sound])
		#expect(notificationCenter.addedRequests.count == 1)
		#expect(notificationCenter.removedIdentifiers.isEmpty)
	}

	@Test
	func `Syncing ineligible reminder cancels without requesting authorization`() async throws {
		let notificationCenter = FakeNotificationCenter(status: .notDetermined)
		let scheduler = makeScheduler(notificationCenter: notificationCenter)
		let goal = makeGoal(
			targetDate: nil,
			reminder: GoalReminder(),
		)

		let didSchedule = try await scheduler.syncReminder(
			for: goal,
			requestsAuthorization: true,
		)

		#expect(didSchedule == false)
		#expect(notificationCenter.requestedAuthorizationOptions == nil)
		#expect(notificationCenter.addedRequests.isEmpty)
		#expect(
			notificationCenter.removedIdentifiers == [
				scheduler.reminderNotificationIdentifier(for: goal.id)
			]
		)
	}

	@Test
	func `Syncing target date without reminder cancels without requesting authorization`() async throws {
		let notificationCenter = FakeNotificationCenter(status: .notDetermined)
		let scheduler = makeScheduler(notificationCenter: notificationCenter)
		let goal = makeGoal(
			targetDate: date(year: 2026, month: 5, day: 21),
			reminder: nil,
		)

		let didSchedule = try await scheduler.syncReminder(
			for: goal,
			requestsAuthorization: true,
		)

		#expect(didSchedule == false)
		#expect(notificationCenter.requestedAuthorizationOptions == nil)
		#expect(notificationCenter.addedRequests.isEmpty)
		#expect(
			notificationCenter.removedIdentifiers == [
				scheduler.reminderNotificationIdentifier(for: goal.id)
			]
		)
	}

	@Test
	func `Syncing denied reminder authorization skips scheduling`() async throws {
		let notificationCenter = FakeNotificationCenter(status: .denied)
		let scheduler = makeScheduler(notificationCenter: notificationCenter)
		let goal = makeGoal(
			targetDate: date(year: 2026, month: 5, day: 21),
			reminder: GoalReminder(),
		)

		let didSchedule = try await scheduler.syncReminder(
			for: goal,
			requestsAuthorization: true,
		)

		#expect(didSchedule == false)
		#expect(notificationCenter.addedRequests.isEmpty)
		#expect(
			notificationCenter.removedIdentifiers == [
				scheduler.reminderNotificationIdentifier(for: goal.id)
			]
		)
	}

	@Test
	func `Syncing reminder revalidates schedule after authorization`() async throws {
		let notificationCenter = FakeNotificationCenter(status: .notDetermined)
		let dates = [
			date(year: 2026, month: 5, day: 20, hour: 8),
			date(year: 2026, month: 5, day: 21, hour: 10)
		]
		var dateIndex = 0
		let scheduler = makeScheduler(
			notificationCenter: notificationCenter,
			now: {
				defer {
					dateIndex = min(dateIndex + 1, dates.count - 1)
				}
				return dates[dateIndex]
			},
		)
		let goal = makeGoal(
			targetDate: date(year: 2026, month: 5, day: 21),
			reminder: GoalReminder(),
		)

		let didSchedule = try await scheduler.syncReminder(
			for: goal,
			requestsAuthorization: true,
		)

		#expect(didSchedule == false)
		#expect(notificationCenter.requestedAuthorizationOptions == [.alert, .sound])
		#expect(notificationCenter.addedRequests.isEmpty)
		#expect(
			notificationCenter.removedIdentifiers == [
				scheduler.reminderNotificationIdentifier(for: goal.id)
			]
		)
	}

	@Test
	func `Scheduling reminder adds calendar notification request`() async throws {
		let goalID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
		let notificationCenter = FakeNotificationCenter()
		let scheduler = makeScheduler(notificationCenter: notificationCenter)
		let goal = makeGoal(
			id: goalID,
			targetDate: date(year: 2026, month: 5, day: 21),
			reminder: GoalReminder(),
		)

		let didSchedule = try await scheduler.scheduleReminder(for: goal)

		let request = try #require(notificationCenter.addedRequests.first)
		let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
		#expect(didSchedule)
		#expect(notificationCenter.addedRequests.count == 1)
		#expect(notificationCenter.removedIdentifiers.isEmpty)
		#expect(request.identifier == scheduler.reminderNotificationIdentifier(for: goalID))
		#expect(request.content.title == "File taxes")
		#expect(request.content.body == "Don't forget to complete today")
		#expect(request.content.sound == .default)
		#expect(
			request.content.userInfo[GoalNotificationPayload.goalIdUserInfoKey] as? String
				== goalID.uuidString
		)
		#expect(trigger.dateComponents.year == 2026)
		#expect(trigger.dateComponents.month == 5)
		#expect(trigger.dateComponents.day == 21)
		#expect(trigger.dateComponents.hour == 9)
		#expect(trigger.dateComponents.minute == 0)
		#expect(trigger.repeats == false)
	}

	@Test
	func `Scheduling one-time reminder uses complete today body`() async throws {
		let notificationCenter = FakeNotificationCenter()
		let scheduler = GoalNotificationScheduler(
			notificationCenter: notificationCenter,
			calendar: calendar,
			now: { date(year: 2026, month: 5, day: 21, hour: 8) },
		)
		let goal = makeGoal(
			targetDate: date(year: 2026, month: 5, day: 21),
			reminder: GoalReminder(),
		)

		let didSchedule = try await scheduler.scheduleReminder(for: goal)

		let request = try #require(notificationCenter.addedRequests.first)
		#expect(didSchedule)
		#expect(request.content.title == "File taxes")
		#expect(request.content.body == "Don't forget to complete today")
	}

	@Test
	func `Scheduling daily recurring reminder repeats every day`() async throws {
		let notificationCenter = FakeNotificationCenter()
		let scheduler = makeScheduler(
			notificationCenter: notificationCenter,
			now: { date(year: 2026, month: 5, day: 21, hour: 8) },
		)
		let goal = makeGoal(
			reminder: GoalReminder(),
			recurrence: GoalRecurrence(cadence: .daily),
		)

		let didSchedule = try await scheduler.scheduleReminder(for: goal)

		let request = try #require(notificationCenter.addedRequests.first)
		let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
		#expect(didSchedule)
		#expect(request.content.body == "Don't forget to complete today")
		#expect(trigger.repeats)
		#expect(trigger.dateComponents.year == nil)
		#expect(trigger.dateComponents.month == nil)
		#expect(trigger.dateComponents.day == nil)
		#expect(trigger.dateComponents.hour == 9)
		#expect(trigger.dateComponents.minute == 0)
	}

	@Test
	func `Syncing recurring reminder without reminder cancels without requesting authorization`()
		async throws
	{
		let notificationCenter = FakeNotificationCenter(status: .notDetermined)
		let scheduler = makeScheduler(notificationCenter: notificationCenter)
		let goal = makeGoal(
			reminder: nil,
			recurrence: GoalRecurrence(cadence: .daily),
		)

		let didSchedule = try await scheduler.syncReminder(
			for: goal,
			requestsAuthorization: true,
		)

		#expect(didSchedule == false)
		#expect(notificationCenter.requestedAuthorizationOptions == nil)
		#expect(notificationCenter.addedRequests.isEmpty)
		#expect(
			notificationCenter.removedIdentifiers == [
				scheduler.reminderNotificationIdentifier(for: goal.id)
			]
		)
	}

	@Test
	func `Scheduling failure leaves existing pending reminder in place`() async throws {
		let notificationCenter = FakeNotificationCenter(addError: TestNotificationError.failed)
		let scheduler = makeScheduler(notificationCenter: notificationCenter)
		let goal = makeGoal(
			targetDate: date(year: 2026, month: 5, day: 21),
			reminder: GoalReminder(),
		)

		await #expect(throws: TestNotificationError.self) {
			try await scheduler.scheduleReminder(for: goal)
		}

		#expect(notificationCenter.removedIdentifiers.isEmpty)
	}

	@Test
	func `Canceling reminders removes stable notification identifiers`() {
		let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
		let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
		let notificationCenter = FakeNotificationCenter()
		let scheduler = makeScheduler(notificationCenter: notificationCenter)

		scheduler.cancelReminders(for: [firstID, secondID])

		#expect(
			notificationCenter.removedIdentifiers == [
				scheduler.reminderNotificationIdentifier(for: firstID),
				scheduler.reminderNotificationIdentifier(for: secondID)
			]
		)
	}

	private func makeScheduler(
		notificationCenter: FakeNotificationCenter,
		now: (() -> Date)? = nil,
	) -> GoalNotificationScheduler {
		GoalNotificationScheduler(
			notificationCenter: notificationCenter,
			calendar: calendar,
			now: now ?? { date(year: 2026, month: 4, day: 21) },
		)
	}

	private func makeGoal(
		id: UUID = UUID(),
		targetDate: Date? = nil,
		reminder: GoalReminder? = nil,
		progress: GoalProgress = .outcome(OutcomeProgress()),
		recurrence: GoalRecurrence? = nil,
	) -> Goal {
		Goal(
			id: id,
			name: "File taxes",
			details: nil,
			targetDate: targetDate,
			reminder: reminder,
			createdAt: date(year: 2026, month: 1, day: 1),
			progress: progress,
			recurrence: recurrence,
		)
	}

	private var calendar: Calendar {
		var calendar = Calendar(identifier: .gregorian)
		calendar.firstWeekday = 2
		return calendar
	}

	private func date(
		year: Int,
		month: Int,
		day: Int,
		hour: Int = 0,
	) -> Date {
		calendar.date(
			from: DateComponents(year: year, month: month, day: day, hour: hour),
		)!
	}
}

// MARK: - FakeNotificationCenter

@MainActor
private final class FakeNotificationCenter: GoalNotificationCenterClient {

	var status: GoalNotificationAuthorizationStatus

	var requestAuthorizationResult: Bool

	var addError: (any Error)?

	var requestedAuthorizationOptions: UNAuthorizationOptions?

	var addedRequests: [UNNotificationRequest] = []

	var removedIdentifiers: [String] = []

	init(
		status: GoalNotificationAuthorizationStatus = .authorized,
		requestAuthorizationResult: Bool = true,
		addError: (any Error)? = nil,
	) {
		self.status = status
		self.requestAuthorizationResult = requestAuthorizationResult
		self.addError = addError
	}

	func authorizationStatus() async -> GoalNotificationAuthorizationStatus {
		status
	}

	func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
		requestedAuthorizationOptions = options
		return requestAuthorizationResult
	}

	func add(_ request: UNNotificationRequest) async throws {
		if let addError {
			throw addError
		}
		addedRequests.append(request)
	}

	func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
		removedIdentifiers.append(contentsOf: identifiers)
	}
}

// MARK: - TestNotificationError

private enum TestNotificationError: Error {
	case failed
}
