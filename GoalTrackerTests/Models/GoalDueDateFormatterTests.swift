//
//  GoalDueDateFormatterTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/11/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalDueDateFormatterTests {
    @Test
    func `Formats dates using medium date style`() {
        let date = makeDate(year: 2026, month: 5, day: 11)

        let formattedDate = GoalDueDateFormatter.string(from: date)

        #expect(formattedDate == expectedMediumDateString(from: date))
    }

    @Test
    func `Formatted dates omit time`() {
        let date = makeDate(year: 2026, month: 5, day: 11, hour: 15, minute: 45)

        let formattedDate = GoalDueDateFormatter.string(from: date)

        #expect(formattedDate.contains("3:45") == false)
        #expect(formattedDate.contains("15:45") == false)
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        minute: Int = 0,
    ) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date!
    }

    private func expectedMediumDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: date)
    }
}
