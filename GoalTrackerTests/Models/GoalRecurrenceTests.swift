//
//  GoalRecurrenceTests.swift
//  GoalTrackerTests
//
//  Created by Codex on 5/28/26.
//

import Foundation
import SwiftData
import Testing

@testable import GoalTracker

@MainActor
struct GoalRecurrenceTests {
    @Test
    func `Daily cadence uses calendar day boundaries`() throws {
        let period = try #require(
            GoalRecurrenceCadence.daily.period(
                containing: date(year: 2026, month: 5, day: 28, hour: 14),
                calendar: calendar,
            )
        )

        #expect(period.start == date(year: 2026, month: 5, day: 28))
        #expect(period.end == date(year: 2026, month: 5, day: 29))
    }

    @Test
    func `Weekly cadence uses calendar first weekday`() throws {
        let period = try #require(
            GoalRecurrenceCadence.weekly.period(
                containing: date(year: 2026, month: 5, day: 28, hour: 14),
                calendar: calendar,
            )
        )

        #expect(period.start == date(year: 2026, month: 5, day: 25))
        #expect(period.end == date(year: 2026, month: 6, day: 1))
    }

    @Test
    func `Monthly cadence uses calendar month boundaries`() throws {
        let period = try #require(
            GoalRecurrenceCadence.monthly.period(
                containing: date(year: 2026, month: 5, day: 28, hour: 14),
                calendar: calendar,
            )
        )

        #expect(period.start == date(year: 2026, month: 5, day: 1))
        #expect(period.end == date(year: 2026, month: 6, day: 1))
    }

    @Test
    func `Yearly cadence uses calendar year boundaries`() throws {
        let period = try #require(
            GoalRecurrenceCadence.yearly.period(
                containing: date(year: 2026, month: 5, day: 28, hour: 14),
                calendar: calendar,
            )
        )

        #expect(period.start == date(year: 2026, month: 1, day: 1))
        #expect(period.end == date(year: 2027, month: 1, day: 1))
    }

    @Test
    func `Cadence can resolve the previous period`() throws {
        let currentPeriod = try #require(
            GoalRecurrenceCadence.monthly.period(
                containing: date(year: 2026, month: 1, day: 28),
                calendar: calendar,
            )
        )
        let previousPeriod = try #require(
            GoalRecurrenceCadence.monthly.period(
                before: currentPeriod,
                calendar: calendar,
            )
        )

        #expect(previousPeriod.start == date(year: 2025, month: 12, day: 1))
        #expect(previousPeriod.end == date(year: 2026, month: 1, day: 1))
    }

    @Test
    func `Recurrence encodes cadence as a stable value`() throws {
        let recurrence = GoalRecurrence(cadence: .weekly)
        let data = try JSONEncoder().encode(recurrence)
        let json = String(decoding: data, as: UTF8.self)

        #expect(json.contains(#""cadence":"weekly""#))
    }

    @Test
    func `Recurrence detail titles describe repeated cadence`() {
        #expect(GoalRecurrence(cadence: .daily).detailTitle == "Repeats every day")
        #expect(GoalRecurrence(cadence: .weekly).detailTitle == "Repeats every week")
        #expect(GoalRecurrence(cadence: .monthly).detailTitle == "Repeats every month")
        #expect(GoalRecurrence(cadence: .yearly).detailTitle == "Repeats every year")
    }

    @Test
    func `Streak value titles pluralize cadence units`() {
        #expect(GoalRecurrenceCadence.daily.streakValueTitle(for: 1) == "1 day")
        #expect(GoalRecurrenceCadence.weekly.streakValueTitle(for: 5) == "5 weeks")
        #expect(GoalRecurrenceCadence.monthly.streakValueTitle(for: 1) == "1 month")
        #expect(GoalRecurrenceCadence.yearly.streakValueTitle(for: 5) == "5 years")
    }

    @Test
    func `Non recurring goal has no current streak`() {
        let goal = Goal(
            name: "Read",
            details: nil,
            createdAt: date(year: 2026, month: 5, day: 28),
            progress: .outcomeCompleted,
        )

        #expect(goal.currentStreak(at: date(year: 2026, month: 5, day: 28), calendar: calendar) == nil)
    }

    @Test
    func `Goal reports whether it is recurring`() {
        let nonRecurringGoal = Goal(
            name: "Read",
            details: nil,
            createdAt: date(year: 2026, month: 5, day: 28),
            progress: .outcomePending,
        )
        let recurringGoal = Goal(
            name: "Run",
            details: nil,
            createdAt: date(year: 2026, month: 5, day: 28),
            progress: .outcomePending,
            recurrence: GoalRecurrence(cadence: .daily),
        )

        #expect(nonRecurringGoal.isRecurring == false)
        #expect(recurringGoal.isRecurring)
    }

    @Test
    func `Incomplete current period preserves previous completed streak`() {
        let goal = Goal(
            name: "Read",
            details: nil,
            createdAt: date(year: 2026, month: 5, day: 28),
            progress: GoalProgress(
                kind: .outcome,
                events: [
                    GoalProgressEvent(delta: 1, timestamp: date(year: 2026, month: 5, day: 27)),
                    GoalProgressEvent(delta: 1, timestamp: date(year: 2026, month: 5, day: 26)),
                ],
                targetValue: 1,
            ),
            recurrence: GoalRecurrence(cadence: .daily),
        )

        #expect(goal.currentStreak(at: date(year: 2026, month: 5, day: 28), calendar: calendar) == 2)
    }

    @Test
    func `Current streak resets after a missed elapsed period`() {
        let goal = Goal(
            name: "Read",
            details: nil,
            createdAt: date(year: 2026, month: 5, day: 26),
            progress: GoalProgress(
                kind: .outcome,
                events: [
                    GoalProgressEvent(delta: 1, timestamp: date(year: 2026, month: 5, day: 26)),
                ],
                targetValue: 1,
            ),
            recurrence: GoalRecurrence(cadence: .daily),
        )

        #expect(goal.currentStreak(at: date(year: 2026, month: 5, day: 28), calendar: calendar) == 0)
    }

    @Test
    func `Current streak ignores progress outside current period`() {
        let goal = Goal(
            name: "Run",
            details: nil,
            createdAt: date(year: 2026, month: 5, day: 28),
            progress: GoalProgress(
                kind: .measurable,
                events: [
                    GoalProgressEvent(delta: 10, timestamp: date(year: 2026, month: 5, day: 29)),
                ],
                targetValue: 10,
            ),
            recurrence: GoalRecurrence(cadence: .daily),
        )

        #expect(goal.currentStreak(at: date(year: 2026, month: 5, day: 28, hour: 12), calendar: calendar) == 0)
    }

    @Test
    func `Daily current streak counts consecutive completed periods`() {
        let goal = Goal(
            name: "Read",
            details: nil,
            createdAt: date(year: 2026, month: 5, day: 28),
            progress: GoalProgress(
                kind: .outcome,
                events: [
                    GoalProgressEvent(delta: 1, timestamp: date(year: 2026, month: 5, day: 28)),
                    GoalProgressEvent(delta: 1, timestamp: date(year: 2026, month: 5, day: 27)),
                    GoalProgressEvent(delta: 1, timestamp: date(year: 2026, month: 5, day: 26)),
                ],
                targetValue: 1,
            ),
            recurrence: GoalRecurrence(cadence: .daily),
        )

        #expect(goal.currentStreak(at: date(year: 2026, month: 5, day: 28, hour: 12), calendar: calendar) == 3)
    }

    @Test
    func `Current streak stops at the first incomplete period`() {
        let goal = Goal(
            name: "Read",
            details: nil,
            createdAt: date(year: 2026, month: 5, day: 25),
            progress: GoalProgress(
                kind: .outcome,
                events: [
                    GoalProgressEvent(delta: 1, timestamp: date(year: 2026, month: 5, day: 28)),
                    GoalProgressEvent(delta: 1, timestamp: date(year: 2026, month: 5, day: 27)),
                    GoalProgressEvent(delta: 1, timestamp: date(year: 2026, month: 5, day: 25)),
                ],
                targetValue: 1,
            ),
            recurrence: GoalRecurrence(cadence: .daily),
        )

        #expect(goal.currentStreak(at: date(year: 2026, month: 5, day: 28, hour: 12), calendar: calendar) == 2)
    }

    @Test
    func `Measurable current streak uses completed cadence periods`() {
        let goal = Goal(
            name: "Run",
            details: nil,
            createdAt: date(year: 2026, month: 5, day: 1),
            progress: GoalProgress(
                kind: .measurable,
                events: [
                    GoalProgressEvent(delta: 10, timestamp: date(year: 2026, month: 5, day: 28)),
                    GoalProgressEvent(delta: 10, timestamp: date(year: 2026, month: 5, day: 21)),
                    GoalProgressEvent(delta: 5, timestamp: date(year: 2026, month: 5, day: 14)),
                ],
                targetValue: 10,
            ),
            recurrence: GoalRecurrence(cadence: .weekly),
        )

        #expect(goal.currentStreak(at: date(year: 2026, month: 5, day: 28, hour: 12), calendar: calendar) == 2)
    }

    @Test
    func `Goal recurrence persists with SwiftData`() throws {
        let container = try GoalTrackerModelContainer.make(isStoredInMemoryOnly: true)
        let goal = Goal(
            name: "Read",
            details: nil,
            createdAt: date(year: 2026, month: 5, day: 28),
            progress: .outcomePending,
            recurrence: GoalRecurrence(cadence: .monthly),
        )
        container.mainContext.insert(goal)
        try container.mainContext.save()

        let fetchedGoals = try container.mainContext.fetch(FetchDescriptor<Goal>())
        let fetchedGoal = try #require(fetchedGoals.first)

        #expect(fetchedGoal.recurrence == GoalRecurrence(cadence: .monthly))
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        guard let timeZone = TimeZone(secondsFromGMT: 0) else {
            preconditionFailure("Unable to create GMT test time zone.")
        }
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
    ) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
        )
        guard let date = components.date else {
            preconditionFailure("Invalid test date.")
        }
        return date
    }
}
