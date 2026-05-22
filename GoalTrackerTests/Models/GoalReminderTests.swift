//
//  GoalReminderTests.swift
//  GoalTrackerTests
//
//  Created by Codex on 5/21/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalReminderTests {
    @Test
    func `New goals default to no early reminder`() {
        let goal = makeGoal()

        #expect(goal.earlyReminder == nil)
    }

    @Test(
        arguments: GoalReminderPreset.allCases,
    )
    func `Goals can be initialized with preset early reminders`(
        preset: GoalReminderPreset,
    ) {
        let goal = makeGoal(earlyReminder: preset.earlyReminder)

        #expect(goal.earlyReminder == preset.earlyReminder)
    }

    @Test
    func `Goals can be initialized with custom early reminders`() {
        let earlyReminder = GoalReminder(secondsBeforeDueDate: 3 * 24 * 60 * 60)
        let goal = makeGoal(earlyReminder: earlyReminder)

        #expect(goal.earlyReminder == earlyReminder)
    }

    @Test
    func `Presets convert to expected early reminders`() {
        #expect(GoalReminderPreset.allCases == [.oneDayBefore, .oneWeekBefore, .oneMonthBefore])
        #expect(GoalReminderPreset.oneDayBefore.earlyReminder == GoalReminder(secondsBeforeDueDate: 86_400))
        #expect(GoalReminderPreset.oneWeekBefore.earlyReminder == GoalReminder(secondsBeforeDueDate: 604_800))
        #expect(GoalReminderPreset.oneMonthBefore.earlyReminder == GoalReminder(secondsBeforeDueDate: 2_592_000))
    }

    @Test
    func `Preset lookup returns matching early reminder preset`() {
        #expect(GoalReminderPreset.preset(for: .onDueDate) == nil)
        #expect(GoalReminderPreset.preset(for: .daysBeforeDueDate(1)) == .oneDayBefore)
        #expect(GoalReminderPreset.preset(for: .daysBeforeDueDate(7)) == .oneWeekBefore)
        #expect(GoalReminderPreset.preset(for: .daysBeforeDueDate(30)) == .oneMonthBefore)
        #expect(GoalReminderPreset.preset(for: .minutesBeforeDueDate(30)) == nil)
    }

    @Test
    func `Date only reminders calculate from nine AM local time`() throws {
        let calendar = Calendar(identifier: .gregorian)
        let dueDate = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 5,
            day: 21,
        )))

        let oneDayBefore = GoalReminder.daysBeforeDueDate(1)
        let oneWeekBefore = GoalReminder.daysBeforeDueDate(7)
        let oneMonthBefore = GoalReminder.daysBeforeDueDate(30)
        let onDueDate = GoalReminder.onDueDate

        #expect(onDueDate.reminderDate(before: dueDate, calendar: calendar) == calendar.date(
            from: DateComponents(year: 2026, month: 5, day: 21, hour: 9),
        ))
        #expect(oneDayBefore.reminderDate(before: dueDate, calendar: calendar) == calendar.date(
            from: DateComponents(year: 2026, month: 5, day: 20, hour: 9),
        ))
        #expect(oneWeekBefore.reminderDate(before: dueDate, calendar: calendar) == calendar.date(
            from: DateComponents(year: 2026, month: 5, day: 14, hour: 9),
        ))
        #expect(oneMonthBefore.reminderDate(before: dueDate, calendar: calendar) == calendar.date(
            from: DateComponents(year: 2026, month: 4, day: 21, hour: 9),
        ))
    }

    @Test
    func `Due time reminders calculate from exact due date time`() throws {
        let calendar = Calendar(identifier: .gregorian)
        let dueDate = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 5,
            day: 21,
            hour: 17,
        )))

        let thirtyMinutesBefore = GoalReminder.minutesBeforeDueDate(30)
        let oneHourBefore = GoalReminder.hoursBeforeDueDate(1)
        let onDueDate = GoalReminder.onDueDate

        #expect(onDueDate.reminderDate(
            before: dueDate,
            dueDateIncludesTime: true,
            calendar: calendar,
        ) == calendar.date(from: DateComponents(year: 2026, month: 5, day: 21, hour: 17)))
        #expect(thirtyMinutesBefore.reminderDate(
            before: dueDate,
            dueDateIncludesTime: true,
            calendar: calendar,
        ) == calendar.date(from: DateComponents(year: 2026, month: 5, day: 21, hour: 16, minute: 30)))
        #expect(oneHourBefore.reminderDate(
            before: dueDate,
            dueDateIncludesTime: true,
            calendar: calendar,
        ) == calendar.date(from: DateComponents(year: 2026, month: 5, day: 21, hour: 16)))
    }

    @Test
    func `Form data preserves early reminders from goals`() {
        let earlyReminder = GoalReminder.daysBeforeDueDate(14)
        let goal = makeGoal(earlyReminder: earlyReminder)

        let data = GoalFormData(goal: goal)

        #expect(data.earlyReminder == earlyReminder)
    }

    @Test
    func `Empty form data has no early reminder`() {
        #expect(GoalFormData.empty.earlyReminder == nil)
    }

    private func makeGoal(
        earlyReminder: GoalReminder? = nil,
    ) -> Goal {
        Goal(
            name: "Test Goal",
            details: nil,
            earlyReminder: earlyReminder,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            progress: .outcomePending,
        )
    }
}
