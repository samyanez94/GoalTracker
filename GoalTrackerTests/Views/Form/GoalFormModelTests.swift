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
        #expect(model.hasDueDate == false)
        #expect(model.reminder == nil)
        #expect(model.isDueDatePickerExpanded == false)
        #expect(model.isProgressBased == false)
        #expect(model.currentValue == nil)
        #expect(model.targetValue == nil)
        #expect(model.step == nil)
        #expect(model.selectedProgressUnit == nil)
        #expect(model.recurrence == nil)
        #expect(model.selectedTags.isEmpty)
        #expect(model.saveFailureKind == .addGoal)
        #expect(model.isSaveDisabled)
    }

    @Test
    func `Edit mode initializes from measurable form data`() {
        let dueDate = Date(timeIntervalSinceReferenceDate: 123)
        let tags = [
            Tag(name: "Health"),
            Tag(name: "Running"),
        ]
        let model = GoalFormModel(
            mode: .edit(
                GoalFormData(
                    name: "Run 10 miles",
                    details: "Weekly long run",
                    dueDate: dueDate,
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
        #expect(model.hasDueDate)
        #expect(model.dueDate == dueDate)
        #expect(model.isProgressBased)
        #expect(model.currentValue == 3)
        #expect(model.targetValue == 10)
        #expect(model.step == 2)
        #expect(model.selectedProgressUnit == .miles)
        #expect(model.recurrence == nil)
        #expect(model.selectedTags.map(\.name) == ["Health", "Running"])
        #expect(model.saveFailureKind == .updateGoal)
    }

    @Test
    func `Edit mode initializes from recurring form data`() {
        let model = GoalFormModel(
            mode: .edit(
                GoalFormData(
                    name: "Run",
                    details: "",
                    progress: .outcomePending,
                    recurrence: GoalRecurrence(cadence: .weekly),
                ),
            ),
        )

        #expect(model.recurrence == GoalRecurrence(cadence: .weekly))
        #expect(model.allowsDueDate == false)
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
        model.currentValue = 0
        model.targetValue = 0
        model.step = 1

        #expect(model.isSaveDisabled)
    }

    @Test
    func `Empty measurable values disable saving`() {
        let model = GoalFormModel(mode: .create)
        model.name = "Read books"
        model.isProgressBased = true

        #expect(model.currentValue == nil)
        #expect(model.targetValue == nil)
        #expect(model.step == nil)
        #expect(model.isSaveDisabled)
    }

    @Test
    func `Create mode disables saving for already complete measurable progress`() {
        let model = GoalFormModel(mode: .create)
        model.name = "Read books"
        model.isProgressBased = true
        model.currentValue = 10
        model.targetValue = 10
        model.step = 1

        #expect(model.isSaveDisabled)
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
    func `Form data includes due date only when due date is enabled`() {
        let dueDate = Date(timeIntervalSinceReferenceDate: 456)
        let reminder = GoalReminder()
        let model = GoalFormModel(mode: .create)
        model.name = "File taxes"
        model.hasDueDate = true
        model.dueDate = dueDate
        model.reminder = reminder

        #expect(model.makeFormData().dueDate == dueDate)
        #expect(model.makeFormData().reminder == reminder)

        model.hasDueDate = false

        #expect(model.makeFormData().dueDate == nil)
        #expect(model.makeFormData().reminder == nil)
    }

    @Test
    func `Selecting recurrence clears due date and reminder`() {
        let dueDate = Date(timeIntervalSinceReferenceDate: 456)
        let reminder = GoalReminder()
        let model = GoalFormModel(mode: .create)
        model.name = "Run"
        model.hasDueDate = true
        model.dueDate = dueDate
        model.reminder = reminder

        model.recurrence = GoalRecurrence(cadence: .daily)

        let data = model.makeFormData()
        #expect(model.hasDueDate == false)
        #expect(model.reminder == nil)
        #expect(model.allowsDueDate == false)
        #expect(data.dueDate == nil)
        #expect(data.reminder == nil)
        #expect(data.recurrence == GoalRecurrence(cadence: .daily))
    }

    @Test
    func `Recurring edit data ignores existing due date`() {
        let model = GoalFormModel(
            mode: .edit(
                GoalFormData(
                    name: "Run",
                    details: "",
                    dueDate: Date(timeIntervalSinceReferenceDate: 456),
                    reminder: GoalReminder(),
                    progress: .outcomePending,
                    recurrence: GoalRecurrence(cadence: .weekly),
                ),
            ),
        )

        let data = model.makeFormData()
        #expect(model.hasDueDate == false)
        #expect(model.reminder == nil)
        #expect(model.allowsDueDate == false)
        #expect(data.dueDate == nil)
        #expect(data.reminder == nil)
        #expect(data.recurrence == GoalRecurrence(cadence: .weekly))
    }

    @Test
    func `Enabling due date does not default reminder`() {
        let model = GoalFormModel(mode: .create)

        model.hasDueDate = true
        model.setDueDateEnabled(true)

        #expect(model.reminder == nil)
    }

    @Test
    func `Enabling due date preserves existing reminder`() {
        let reminder = GoalReminder()
        let model = GoalFormModel(mode: .create)
        model.reminder = reminder

        model.hasDueDate = true
        model.setDueDateEnabled(true)

        #expect(model.reminder == reminder)
    }

    @Test
    func `Disabling due date clears reminder`() {
        let model = GoalFormModel(mode: .create)
        model.hasDueDate = true
        model.setDueDateEnabled(true)

        model.hasDueDate = false
        model.setDueDateEnabled(false)

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
                    dueDate: Date(timeIntervalSinceReferenceDate: 456),
                    reminder: reminder,
                    progress: .outcomePending,
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
            Tag(name: "Running"),
        ]
        let model = GoalFormModel(
            mode: .edit(
                GoalFormData(
                    name: "Run",
                    details: "",
                    progress: .outcomePending,
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

        let data = model.makeFormData()

        #expect(data.recurrence == GoalRecurrence(cadence: .daily))
    }

    @Test
    func `Form data preserves never recurrence`() {
        let model = GoalFormModel(
            mode: .edit(
                GoalFormData(
                    name: "Read",
                    details: "",
                    progress: .outcomePending,
                    recurrence: GoalRecurrence(cadence: .yearly),
                ),
            ),
        )
        model.recurrence = nil

        let data = model.makeFormData()

        #expect(data.recurrence == nil)
    }

    @Test
    func `Create form data stores initial measurable progress as timestamped event`() throws {
        let timestamp = Date(timeIntervalSinceReferenceDate: 789)
        let model = GoalFormModel(mode: .create, now: { timestamp })
        model.name = "Read books"
        model.isProgressBased = true
        model.currentValue = 2
        model.targetValue = 10
        model.step = 1

        let data = model.makeFormData()

        let event = try #require(data.progress.events.first)
        #expect(data.progress.currentValue == 2)
        #expect(event.delta == 2)
        #expect(event.timestamp == timestamp)
    }

    @Test
    func `Edit form data represents updated measurable current value`() {
        let model = GoalFormModel(
            mode: .edit(
                GoalFormData(
                    name: "Read books",
                    details: "",
                    progress: .measurable(currentValue: 2, targetValue: 10),
                ),
            ),
            now: { Date(timeIntervalSinceReferenceDate: 789) },
        )
        model.currentValue = 5

        let data = model.makeFormData()

        #expect(data.progress.currentValue == 5)
    }

    @Test
    func `Completed outcome edit remains completed in form data`() {
        let model = GoalFormModel(
            mode: .edit(
                GoalFormData(
                    name: "Book trip",
                    details: "",
                    progress: .outcomeCompleted,
                ),
            ),
        )

        let data = model.makeFormData()

        #expect(data.progress.kind == .outcome)
        #expect(data.progress.isCompleted)
    }

    @Test
    func `Due date expansion follows due date enablement`() {
        let model = GoalFormModel(mode: .create)

        model.toggleDueDatePicker()
        #expect(model.isDueDatePickerExpanded == false)

        model.hasDueDate = true
        model.setDueDateEnabled(true)
        #expect(model.isDueDatePickerExpanded)

        model.toggleDueDatePicker()
        #expect(model.isDueDatePickerExpanded == false)
    }
}
