//
//  DebugSeedData.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/12/26.
//

#if DEBUG

import Foundation

// MARK: - DebugSeedData

@MainActor
enum DebugSeedData {
	static func appStoreScreenshots(
		referenceDate: Date = Date(),
		calendar: Calendar = .current,
	) -> (tags: [Tag], goals: [Goal]) {
		let fitness = tag("Fitness", daysAgo: 30, referenceDate: referenceDate, calendar: calendar)

		let goals = [
			Goal(
				name: "Save for Japan trip",
				details: "Set aside money for flights, lodging, food, and a few special experiences.",
				createdAt: date(byAdding: .day, value: -1, to: referenceDate, calendar: calendar),
				progress: .measurable(
					currentValue: 1_300,
					targetValue: 3_000,
					step: 100,
					unit: .dollars,
					timestamp: referenceDate,
				),
			),
			Goal(
				name: "Run 100 miles",
				details: "Keep building mileage with steady runs throughout the month.",
				createdAt: date(byAdding: .day, value: -2, to: referenceDate, calendar: calendar),
				progress: .measurable(
					currentValue: 0,
					targetValue: 100,
					step: 1,
					unit: .miles,
					timestamp: referenceDate,
				),
			),
			Goal(
				name: "Read 12 books",
				details: "Make room for more reading before bed and on quiet weekends.",
				targetDate: date(byAdding: .month, value: 6, to: referenceDate, calendar: calendar),
				createdAt: date(byAdding: .day, value: -3, to: referenceDate, calendar: calendar),
				progress: .measurable(
					currentValue: 0,
					targetValue: 12,
					unit: .books,
					timestamp: referenceDate,
				),
			),
			Goal(
				name: "Morning walk",
				details: "Start the day with a short walk outside before checking messages or work.",
				createdAt: date(byAdding: .day, value: -4, to: referenceDate, calendar: calendar),
				progress: .outcome(
					OutcomeProgress(
						events: [
							GoalProgressEvent(
								delta: 1,
								timestamp: date(
									byAdding: .day,
									value: -1,
									to: referenceDate,
									calendar: calendar,
								)
							),
							GoalProgressEvent(
								delta: 1,
								timestamp: date(
									byAdding: .day,
									value: -2,
									to: referenceDate,
									calendar: calendar,
								)
							),
							GoalProgressEvent(
								delta: 1,
								timestamp: date(
									byAdding: .day,
									value: -3,
									to: referenceDate,
									calendar: calendar,
								)
							)
						]
					)
				),
				recurrence: GoalRecurrence(cadence: .daily),
			),
			Goal(
				name: "Finish portfolio website",
				details: "Refresh the case studies and publish the latest work.",
				createdAt: date(byAdding: .day, value: -5, to: referenceDate, calendar: calendar),
				progress: .outcome(
					OutcomeProgress.completed(
						timestamp: date(byAdding: .day, value: -5, to: referenceDate, calendar: calendar)
					)
				),
			),
			Goal(
				name: "Donate old clothes",
				details: "Sort the closet and drop off donation bags.",
				createdAt: date(byAdding: .day, value: -6, to: referenceDate, calendar: calendar),
				progress: .outcome(
					OutcomeProgress.completed(
						timestamp: date(byAdding: .day, value: -6, to: referenceDate, calendar: calendar)
					)
				),
			)
		]

		goals[1].tags = [fitness]
		goals[3].tags = [fitness]

		return (
			tags: [fitness],
			goals: goals
		)
	}

	private static func tag(
		_ name: String,
		daysAgo: Int,
		referenceDate: Date,
		calendar: Calendar,
	) -> Tag {
		Tag(
			name: name,
			createdAt: date(byAdding: .day, value: -daysAgo, to: referenceDate, calendar: calendar)
		)
	}

	private static func date(
		byAdding component: Calendar.Component,
		value: Int,
		to referenceDate: Date,
		calendar: Calendar,
	) -> Date {
		calendar.date(byAdding: component, value: value, to: referenceDate) ?? referenceDate
	}
}

#endif
