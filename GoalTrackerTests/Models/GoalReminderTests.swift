//
//  GoalReminderTests.swift
//  GoalTrackerTests
//
//  Created by Codex on 5/21/26.
//

import Foundation
import Testing
import UserNotifications

@testable import GoalTracker

@MainActor
struct GoalReminderTests {
    @Test
    func `New goals default to no reminder`() {
        let goal = makeGoal()

        #expect(goal.reminder == nil)
    }

    @Test(
        arguments: GoalReminderPreset.allCases,
    )
    func `Goals can be initialized with preset reminders`(
        preset: GoalReminderPreset,
    ) {
        let goal = makeGoal(reminder: preset.reminder)

        #expect(goal.reminder == preset.reminder)
    }

    @Test
    func `Goals can be initialized with custom reminders`() {
        let reminder = GoalReminder(secondsBeforeDueDate: 3 * 24 * 60 * 60)
        let goal = makeGoal(reminder: reminder)

        #expect(goal.reminder == reminder)
    }

    @Test
    func `Presets convert to expected reminders`() {
        #expect(GoalReminderPreset.onDueDate.reminder == GoalReminder(secondsBeforeDueDate: 0))
        #expect(GoalReminderPreset.oneDayBefore.reminder == GoalReminder(secondsBeforeDueDate: 86_400))
        #expect(GoalReminderPreset.oneWeekBefore.reminder == GoalReminder(secondsBeforeDueDate: 604_800))
        #expect(GoalReminderPreset.oneMonthBefore.reminder == GoalReminder(secondsBeforeDueDate: 2_592_000))
    }

    @Test
    func `Preset lookup returns matching reminder preset`() {
        #expect(GoalReminderPreset.preset(for: .onDueDate) == .onDueDate)
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
    func `Reminder creates notification content`() throws {
        let calendar = Calendar(identifier: .gregorian)
        let reminder = GoalReminder.daysBeforeDueDate(1)
        let currentDate = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 4,
            day: 21,
        )))
        let dueDate = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 5,
            day: 21,
        )))

        let content = reminder.notificationContent(
            goalName: "File taxes",
            dueDate: dueDate,
            relativeTo: currentDate,
            calendar: calendar,
        )

        #expect(content.title == "File taxes")
        #expect(content.body == "Complete by next month")
        #expect(content.sound == .default)
    }

    @Test
    func `Form data preserves reminders from goals`() {
        let reminder = GoalReminder.daysBeforeDueDate(14)
        let goal = makeGoal(reminder: reminder)

        let data = GoalFormData(goal: goal)

        #expect(data.reminder == reminder)
    }

    @Test
    func `Empty form data has no reminder`() {
        #expect(GoalFormData.empty.reminder == nil)
    }

    private func makeGoal(
        reminder: GoalReminder? = nil,
    ) -> Goal {
        Goal(
            name: "Test Goal",
            details: nil,
            reminder: reminder,
            createdAt: Date(timeIntervalSinceReferenceDate: 0),
            progress: .outcomePending,
        )
    }
}
