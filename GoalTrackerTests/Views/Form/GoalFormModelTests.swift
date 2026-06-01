//
//  GoalFormModelTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/15/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalFormModelTests {
	@Test
	func `Create mode starts with empty outcome goal defaults`() {
		let model = GoalFormModel(mode: .create)

		#expect(model.name == "")
		#expect(model.details == "")
		#expect(model.hasTargetDate == false)
		#expect(model.reminder == nil)
		#expect(model.isTargetDatePickerExpanded == false)
		#expect(model.isProgressBased == false)
		#expect(model.targetValue == 1)
		#expect(model.step == 1)
		#expect(model.selectedProgressUnit == nil)
		#expect(model.recurrence == nil)
		#expect(model.selectedTags.isEmpty)
		#expect(model.saveFailureKind == .addGoal)
		#expect(model.isSaveDisabled)
		#expect(model.hasChanges == false)
	}

	@Test
	func `Changing form data marks model as changed`() {
		let model = GoalFormModel(mode: .create)

		model.name = "Read"

		#expect(model.hasChanges)
	}

	@Test
	func `Reverting form data clears changed state`() {
		let model = GoalFormModel(mode: .create)

		model.name = "Read"
		model.name = ""

		#expect(model.hasChanges == false)
	}

	@Test
	func `Hidden progress values do not mark outcome goal as changed`() {
		let model = GoalFormModel(mode: .create)

		model.targetValue = 10
		model.step = 2

		#expect(model.hasChanges == false)
	}

	@Test
	func `Enabling progress tracking marks model as changed`() {
		let model = GoalFormModel(mode: .create)

		model.isProgressBased = true

		#expect(model.hasChanges)
	}

	@Test
	func `Edit mode initializes from measurable form data`() {
		let targetDate = Date(timeIntervalSinceReferenceDate: 123)
		let tags = [
			Tag(name: "Health"),
			Tag(name: "Running")
		]
		let model = GoalFormModel(
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

		#expect(model.name == "Run 10 miles")
		#expect(model.details == "Weekly long run")
		#expect(model.hasTargetDate)
		#expect(model.targetDate == targetDate)
		#expect(model.isProgressBased)
		#expect(model.targetValue == 10)
		#expect(model.step == 2)
		#expect(model.selectedProgressUnit == .miles)
		#expect(model.recurrence == nil)
		#expect(model.selectedTags.map(\.name) == ["Health", "Running"])
		#expect(model.saveFailureKind == .updateGoal)
	}

	@Test
	func `Edit mode initializes from recurring form data`() {
		let reminder = GoalReminder()
		let model = GoalFormModel(
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

		#expect(model.recurrence == GoalRecurrence(cadence: .weekly))
		#expect(model.reminder == reminder)
		#expect(model.allowsTargetDate == false)
	}

	@Test
	func `Empty or whitespace name disables saving`() {
		let model = GoalFormModel(mode: .create)

		model.name = "   "

		#expect(model.isSaveDisabled)
	}

	@Test
	func `Invalid measurable values disable saving`() {
		let model = GoalFormModel(mode: .create)
		model.name = "Read books"
		model.isProgressBased = true
		model.targetValue = 0
		model.step = 1

		#expect(model.isSaveDisabled)
	}

	@Test
	func `Default measurable values allow saving`() {
		let model = GoalFormModel(mode: .create)
		model.name = "Read books"
		model.isProgressBased = true

		#expect(model.targetValue == 1)
		#expect(model.step == 1)
		#expect(model.isSaveDisabled == false)
	}

	@Test
	func `Edit mode allows saving complete measurable progress`() {
		let model = GoalFormModel(
			mode: .edit(
				GoalFormData(
					name: "Read books",
					details: "",
					progress: .measurable(currentValue: 10, targetValue: 10),
				),
			),
		)

		#expect(model.isSaveDisabled == false)
	}

	@Test
	func `Form data includes target date only when target date is enabled`() {
		let targetDate = Date(timeIntervalSinceReferenceDate: 456)
		let reminder = GoalReminder()
		let model = GoalFormModel(mode: .create)
		model.name = "File taxes"
		model.hasTargetDate = true
		model.targetDate = targetDate
		model.reminder = reminder

		#expect(model.makeFormData().targetDate == targetDate)
		#expect(model.makeFormData().reminder == reminder)

		model.hasTargetDate = false

		#expect(model.makeFormData().targetDate == nil)
		#expect(model.makeFormData().reminder == nil)
	}

	@Test
	func `Selecting recurrence clears target date and preserves reminder`() {
		let targetDate = Date(timeIntervalSinceReferenceDate: 456)
		let reminder = GoalReminder()
		let model = GoalFormModel(mode: .create)
		model.name = "Run"
		model.hasTargetDate = true
		model.targetDate = targetDate
		model.reminder = reminder

		model.recurrence = GoalRecurrence(cadence: .daily)

		let data = model.makeFormData()
		#expect(model.hasTargetDate == false)
		#expect(model.reminder == reminder)
		#expect(model.allowsTargetDate == false)
		#expect(data.targetDate == nil)
		#expect(data.reminder == reminder)
		#expect(data.recurrence == GoalRecurrence(cadence: .daily))
	}

	@Test
	func `Recurring edit data ignores existing target date and preserves reminder`() {
		let reminder = GoalReminder()
		let model = GoalFormModel(
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

		let data = model.makeFormData()
		#expect(model.hasTargetDate == false)
		#expect(model.reminder == reminder)
		#expect(model.allowsTargetDate == false)
		#expect(data.targetDate == nil)
		#expect(data.reminder == reminder)
		#expect(data.recurrence == GoalRecurrence(cadence: .weekly))
	}

	@Test
	func `Enabling target date does not default reminder`() {
		let model = GoalFormModel(mode: .create)

		model.hasTargetDate = true
		model.setTargetDateEnabled(true)

		#expect(model.reminder == nil)
	}

	@Test
	func `Enabling target date preserves existing reminder`() {
		let reminder = GoalReminder()
		let model = GoalFormModel(mode: .create)
		model.reminder = reminder

		model.hasTargetDate = true
		model.setTargetDateEnabled(true)

		#expect(model.reminder == reminder)
	}

	@Test
	func `Disabling target date clears reminder`() {
		let model = GoalFormModel(mode: .create)
		model.hasTargetDate = true
		model.setTargetDateEnabled(true)

		model.hasTargetDate = false
		model.setTargetDateEnabled(false)

		#expect(model.reminder == nil)
	}

	@Test
	func `Edit mode preserves reminder in form data`() {
		let reminder = GoalReminder()
		let model = GoalFormModel(
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

		#expect(model.makeFormData().reminder == reminder)
	}

	@Test
	func `Form data trims name and preserves details for normalization`() {
		let model = GoalFormModel(mode: .create)
		model.name = "  Write draft  "
		model.details = "   "

		let data = model.makeFormData()

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
		let model = GoalFormModel(
			mode: .edit(
				GoalFormData(
					name: "Run",
					details: "",
					progress: .outcome(OutcomeProgress()),
					tags: tags,
				),
			),
		)

		let data = model.makeFormData()

		#expect(data.tags.map(\.name) == ["Health", "Running"])
	}

	@Test
	func `Form data preserves selected recurrence`() {
		let model = GoalFormModel(mode: .create)
		model.name = "Read"
		model.recurrence = GoalRecurrence(cadence: .daily)
		model.reminder = GoalReminder()

		let data = model.makeFormData()

		#expect(data.recurrence == GoalRecurrence(cadence: .daily))
		#expect(data.reminder == GoalReminder())
	}

	@Test
	func `Form data preserves never recurrence`() {
		let model = GoalFormModel(
			mode: .edit(
				GoalFormData(
					name: "Read",
					details: "",
					progress: .outcome(OutcomeProgress()),
					recurrence: GoalRecurrence(cadence: .yearly),
				),
			),
		)
		model.recurrence = nil

		let data = model.makeFormData()

		#expect(data.recurrence == nil)
	}

	@Test
	func `Completed outcome edit remains completed in form data`() {
		let model = GoalFormModel(
			mode: .edit(
				GoalFormData(
					name: "Book trip",
					details: "",
					progress: .outcome(OutcomeProgress.completed(timestamp: Date())),
				),
			),
		)

		let data = model.makeFormData()

		#expect(data.progress.outcomeProgress != nil)
		#expect(data.progress.isCompleted)
	}

	@Test
	func `Target date expansion follows target date enablement`() {
		let model = GoalFormModel(mode: .create)

		model.toggleTargetDatePicker()
		#expect(model.isTargetDatePickerExpanded == false)

		model.hasTargetDate = true
		model.setTargetDateEnabled(true)
		#expect(model.isTargetDatePickerExpanded)

		model.toggleTargetDatePicker()
		#expect(model.isTargetDatePickerExpanded == false)
	}
}
