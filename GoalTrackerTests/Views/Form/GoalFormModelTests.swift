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
        #expect(model.isDueDatePickerExpanded == false)
        #expect(model.isProgressBased == false)
        #expect(model.currentValue == 0)
        #expect(model.targetValue == 1)
        #expect(model.step == 1)
        #expect(model.selectedProgressUnit == nil)
        #expect(model.saveFailureKind == .addGoal)
        #expect(model.isSaveDisabled)
    }

    @Test
    func `Edit mode initializes from measurable form data`() {
        let dueDate = Date(timeIntervalSinceReferenceDate: 123)
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
        #expect(model.saveFailureKind == .updateGoal)
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
        let model = GoalFormModel(mode: .create)
        model.name = "File taxes"
        model.hasDueDate = true
        model.dueDate = dueDate

        #expect(model.makeFormData().dueDate == dueDate)

        model.hasDueDate = false

        #expect(model.makeFormData().dueDate == nil)
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
