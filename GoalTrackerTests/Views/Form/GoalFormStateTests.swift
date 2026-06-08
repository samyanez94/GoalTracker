//
//  GoalFormStateTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/15/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalFormStateTests {
	@Test
	func `Create mode starts with empty outcome goal defaults`() {
		let state = GoalFormState(mode: .create)

		#expect(state.name == "")
		#expect(state.details == "")
		#expect(state.schedule.hasTargetDate == false)
		#expect(state.schedule.reminder == nil)
		#expect(state.progress.isProgressBased == false)
		#expect(state.progress.targetValue == nil)
		#expect(state.progress.step == nil)
		#expect(state.progress.selectedUnit == nil)
		#expect(state.schedule.recurrence == nil)
		#expect(state.selectedTags.isEmpty)
		#expect(state.saveFailureKind == .addGoal)
		#expect(state.isSaveDisabled)
		#expect(state.hasChanges == false)
	}

	@Test
	func `Changing form data marks state as changed`() {
		let state = GoalFormState(mode: .create)

		state.name = "Read"

		#expect(state.hasChanges)
	}

	@Test
	func `Reverting form data clears changed state`() {
		let state = GoalFormState(mode: .create)

		state.name = "Read"
		state.name = ""

		#expect(state.hasChanges == false)
	}

	@Test
	func `Hidden progress values do not mark outcome goal as changed`() {
		let state = GoalFormState(mode: .create)

		state.progress.targetValue = 10
		state.progress.step = 2

		#expect(state.hasChanges == false)
	}

	@Test
	func `Enabling progress tracking marks state as changed`() {
		let state = GoalFormState(mode: .create)

		state.progress.isProgressBased = true

		#expect(state.hasChanges)
	}

	@Test
	func `Edit mode initializes from measurable form data`() {
		let targetDate = Date(timeIntervalSinceReferenceDate: 123)
		let tags = [
			Tag(name: "Health"),
			Tag(name: "Running")
		]
		let state = GoalFormState(
			mode: .edit(
				GoalFormData(
					name: "Run 10 miles",
					details: "Weekly long run",
					targetDate: targetDate,
					progress: .measurable(
						currentValue: 3,
						targetValue: 10,
						step: 2,
						unit: .miles,
					),
					tags: tags,
				),
			),
		)

		#expect(state.name == "Run 10 miles")
		#expect(state.details == "Weekly long run")
		#expect(state.schedule.hasTargetDate)
		#expect(state.schedule.draftTargetDate == targetDate)
		#expect(state.progress.isProgressBased)
		#expect(state.progress.targetValue == 10)
		#expect(state.progress.step == 2)
		#expect(state.progress.selectedUnit == .miles)
		#expect(state.schedule.recurrence == nil)
		#expect(state.selectedTags.map(\.name) == ["Health", "Running"])
		#expect(state.saveFailureKind == .updateGoal)
	}

	@Test
	func `Edit mode initializes from recurring form data`() {
		let reminder = GoalReminder()
		let state = GoalFormState(
			mode: .edit(
				GoalFormData(
					name: "Run",
					details: "",
					reminder: reminder,
					progress: .outcome(OutcomeProgress()),
					recurrence: GoalRecurrence(cadence: .weekly),
				),
			),
		)

		#expect(state.schedule.recurrence == GoalRecurrence(cadence: .weekly))
		#expect(state.schedule.reminder == reminder)
		#expect(state.schedule.allowsTargetDate == false)
	}

	@Test
	func `Empty or whitespace name disables saving`() {
		let state = GoalFormState(mode: .create)

		state.name = "   "

		#expect(state.isSaveDisabled)
	}

	@Test
	func `Invalid measurable values disable saving`() {
		let state = GoalFormState(mode: .create)
		state.name = "Read books"
		state.progress.isProgressBased = true
		state.progress.targetValue = 0
		state.progress.step = 1

		#expect(state.isSaveDisabled)
	}

	@Test
	func `Default measurable values allow saving`() {
		let state = GoalFormState(mode: .create)
		state.name = "Read books"
		state.progress.isProgressBased = true

		#expect(state.progress.targetValue == nil)
		#expect(state.progress.step == nil)
		#expect(state.isSaveDisabled == false)
	}

	@Test
	func `Blank measurable values default to one in form data`() throws {
		let state = GoalFormState(mode: .create)
		state.name = "Read books"
		state.progress.isProgressBased = true

		let progress = try #require(state.makeFormData().progress.measurableProgress)

		#expect(progress.targetValue == 1)
		#expect(progress.step == 1)
	}

	@Test
	func `Edit mode allows saving complete measurable progress`() {
		let state = GoalFormState(
			mode: .edit(
				GoalFormData(
					name: "Read books",
					details: "",
					progress: .measurable(currentValue: 10, targetValue: 10),
				),
			),
		)

		#expect(state.isSaveDisabled == false)
	}

	@Test
	func `Form data includes target date only when target date is enabled`() {
		let targetDate = Date(timeIntervalSinceReferenceDate: 456)
		let reminder = GoalReminder()
		let state = GoalFormState(mode: .create)
		state.name = "File taxes"
		state.schedule.hasTargetDate = true
		state.schedule.draftTargetDate = targetDate
		state.schedule.reminder = reminder

		#expect(state.makeFormData().targetDate == targetDate)
		#expect(state.makeFormData().reminder == reminder)

		state.schedule.hasTargetDate = false

		#expect(state.makeFormData().targetDate == nil)
		#expect(state.makeFormData().reminder == nil)
	}

	@Test
	func `Selecting recurrence clears target date and preserves reminder`() {
		let targetDate = Date(timeIntervalSinceReferenceDate: 456)
		let reminder = GoalReminder()
		let state = GoalFormState(mode: .create)
		state.name = "Run"
		state.schedule.hasTargetDate = true
		state.schedule.draftTargetDate = targetDate
		state.schedule.reminder = reminder

		state.schedule.recurrence = GoalRecurrence(cadence: .daily)

		let data = state.makeFormData()
		#expect(state.schedule.hasTargetDate == false)
		#expect(state.schedule.reminder == reminder)
		#expect(state.schedule.allowsTargetDate == false)
		#expect(data.targetDate == nil)
		#expect(data.reminder == reminder)
		#expect(data.recurrence == GoalRecurrence(cadence: .daily))
	}

	@Test
	func `Recurring edit data ignores existing target date and preserves reminder`() {
		let reminder = GoalReminder()
		let state = GoalFormState(
			mode: .edit(
				GoalFormData(
					name: "Run",
					details: "",
					targetDate: Date(timeIntervalSinceReferenceDate: 456),
					reminder: reminder,
					progress: .outcome(OutcomeProgress()),
					recurrence: GoalRecurrence(cadence: .weekly),
				),
			),
		)

		let data = state.makeFormData()
		#expect(state.schedule.hasTargetDate == false)
		#expect(state.schedule.reminder == reminder)
		#expect(state.schedule.allowsTargetDate == false)
		#expect(data.targetDate == nil)
		#expect(data.reminder == reminder)
		#expect(data.recurrence == GoalRecurrence(cadence: .weekly))
	}

	@Test
	func `Enabling target date does not default reminder`() {
		let state = GoalFormState(mode: .create)

		state.schedule.hasTargetDate = true

		#expect(state.schedule.reminder == nil)
	}

	@Test
	func `Enabling target date preserves existing reminder`() {
		let reminder = GoalReminder()
		let state = GoalFormState(mode: .create)
		state.schedule.reminder = reminder

		state.schedule.hasTargetDate = true

		#expect(state.schedule.reminder == reminder)
	}

	@Test
	func `Disabling target date clears reminder`() {
		let state = GoalFormState(mode: .create)
		state.schedule.hasTargetDate = true

		state.schedule.hasTargetDate = false

		#expect(state.schedule.reminder == nil)
	}

	@Test
	func `Edit mode preserves reminder in form data`() {
		let reminder = GoalReminder()
		let state = GoalFormState(
			mode: .edit(
				GoalFormData(
					name: "File taxes",
					details: "",
					targetDate: Date(timeIntervalSinceReferenceDate: 456),
					reminder: reminder,
					progress: .outcome(OutcomeProgress()),
				),
			),
		)

		#expect(state.makeFormData().reminder == reminder)
	}

	@Test
	func `Form data trims name and preserves details for normalization`() {
		let state = GoalFormState(mode: .create)
		state.name = "  Write draft  "
		state.details = "   "

		let data = state.makeFormData()

		#expect(data.name == "Write draft")
		#expect(data.details == "   ")
		#expect(data.normalizedDetails == nil)
	}

	@Test
	func `Form data preserves selected tags`() {
		let tags = [
			Tag(name: "Health"),
			Tag(name: "Running")
		]
		let state = GoalFormState(
			mode: .edit(
				GoalFormData(
					name: "Run",
					details: "",
					progress: .outcome(OutcomeProgress()),
					tags: tags,
				),
			),
		)

		let data = state.makeFormData()

		#expect(data.tags.map(\.name) == ["Health", "Running"])
	}

	@Test
	func `Form data preserves selected recurrence`() {
		let state = GoalFormState(mode: .create)
		state.name = "Read"
		state.schedule.recurrence = GoalRecurrence(cadence: .daily)
		state.schedule.reminder = GoalReminder()

		let data = state.makeFormData()

		#expect(data.recurrence == GoalRecurrence(cadence: .daily))
		#expect(data.reminder == GoalReminder())
	}

	@Test
	func `Form data preserves never recurrence`() {
		let state = GoalFormState(
			mode: .edit(
				GoalFormData(
					name: "Read",
					details: "",
					progress: .outcome(OutcomeProgress()),
					recurrence: GoalRecurrence(cadence: .yearly),
				),
			),
		)
		state.schedule.recurrence = nil

		let data = state.makeFormData()

		#expect(data.recurrence == nil)
	}

	@Test
	func `Completed outcome edit remains completed in form data`() {
		let state = GoalFormState(
			mode: .edit(
				GoalFormData(
					name: "Book trip",
					details: "",
					progress: .outcome(OutcomeProgress.completed(timestamp: Date())),
				),
			),
		)

		let data = state.makeFormData()

		#expect(data.progress.outcomeProgress != nil)
		#expect(data.progress.isCompleted)
	}

	@Test
	func `Target date enablement stores and clears draft target date`() {
		let targetDate = Date(timeIntervalSinceReferenceDate: 789)
		let state = GoalFormState(mode: .create)

		state.schedule.draftTargetDate = targetDate

		state.schedule.hasTargetDate = true
		#expect(state.schedule.targetDate == targetDate)

		state.schedule.hasTargetDate = false
		#expect(state.schedule.targetDate == nil)
	}
}
