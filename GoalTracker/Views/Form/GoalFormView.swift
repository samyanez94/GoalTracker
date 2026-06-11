//
//  GoalFormView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/3/26.
//

import SwiftUI

// MARK: - GoalFormMode

/// Describes whether the goal form should create a new goal or edit existing form data.
enum GoalFormMode {
	/// Creates an empty form for a new goal.
	case create

	/// Create a form with pre-filled values for editing.
	case edit(GoalFormData)

	var title: LocalizedStringResource {
		switch self {
		case .create:
			.goalFormTitleCreate
		case .edit:
			.goalFormTitleEdit
		}
	}

	var initialData: GoalFormData {
		switch self {
		case .create:
			.empty
		case .edit(let data):
			data
		}
	}
}

// MARK: - GoalFormDestination

private enum GoalFormDestination: Hashable {
	case tags
	case progressUnit
}

// MARK: - GoalFormView

struct GoalFormView: View {
	@Environment(\.dismiss) private var dismiss

	@State private var formState: GoalFormState

	@FocusState private var isTextInputFocused: Bool

	@State private var isShowingConfirmation = false

	@State private var saveFailure: GoalSaveFailure?

	private let mode: GoalFormMode

	private let onSave: (GoalFormData) throws -> Void

	init(
		mode: GoalFormMode,
		onSave: @escaping (GoalFormData) throws -> Void,
	) {
		self.mode = mode
		self.onSave = onSave
		_formState = State(initialValue: GoalFormState(mode: mode))
	}

	var body: some View {
		// The view owns the form state with @State; @Bindable exposes bindings to its fields.
		@Bindable var formState = formState

		Form {
			Section {
				TextField(.goalFormGoalNameField, text: $formState.name)
					.focused($isTextInputFocused)
				TextField(
					.goalFormDescriptionField,
					text: $formState.details,
					axis: .vertical,
				)
				.focused($isTextInputFocused)
				.lineLimit(1...6)
			} header: {
				Text(.goalFormDetailsSection)
			}
			Section {
				NavigationLink(value: GoalFormDestination.tags) {
					HStack {
						Label {
							Text(.commonTags)
						} icon: {
							Image(systemName: "number")
								.foregroundStyle(.secondary)
						}
						Spacer()
						if hasSelectedTags(in: formState.tagSelections) {
							Text(tagSelectionSummary(for: formState.tagSelections))
								.foregroundStyle(.secondary)
						}
					}
				}
			} header: {
				Text(.goalFormOrganizationSection)
			} footer: {
				Text(.goalFormOrganizationFooter)
					.font(.footnote)
			}
			Section {
				GoalRecurrencePickerRow(recurrence: $formState.schedule.recurrence)
				if formState.schedule.recurrence != nil {
					GoalReminderToggleRow(reminder: $formState.schedule.reminder)
				}
			} header: {
				Text(.goalFormRecurrenceSection)
			} footer: {
				Text(.goalFormRecurrenceFooter)
					.font(.footnote)
			}
			if formState.schedule.allowsTargetDate {
				Section {
					Toggle(isOn: $formState.schedule.hasTargetDate) {
						Label {
							VStack(alignment: .leading, spacing: 2) {
								Text(.goalFormTargetDate)
								if formState.schedule.hasTargetDate {
									Text(GoalTargetDateFormatter.string(from: formState.schedule.draftTargetDate))
										.font(.subheadline)
										.foregroundStyle(.secondary)
								}
							}
						} icon: {
							Image(systemName: "calendar")
								.foregroundStyle(.secondary)
						}
					}
					if formState.schedule.hasTargetDate {
						DatePicker(
							String(localized: .goalFormSelectTargetDate),
							selection: $formState.schedule.draftTargetDate,
							displayedComponents: .date,
						)
						.datePickerStyle(.graphical)
						GoalReminderToggleRow(reminder: $formState.schedule.reminder)
					}
				} header: {
					Text(.goalFormDateSection)
				} footer: {
					Text(.goalFormDateFooter)
						.font(.footnote)
				}
			}
			Section {
				Toggle(isOn: $formState.progress.isProgressBased) {
					Label {
						Text(.goalFormProgressTrackProgress)
					} icon: {
						Image(systemName: "plus.forwardslash.minus")
							.foregroundStyle(.secondary)
					}
				}
				if formState.progress.isProgressBased {
					ProgressTextFieldRow(
						label: .goalFormTargetValueField,
						placeholder: "1",
						value: $formState.progress.targetValue,
						focus: $isTextInputFocused,
					)
					ProgressTextFieldRow(
						label: .goalFormStepField,
						placeholder: "1",
						value: $formState.progress.step,
						focus: $isTextInputFocused,
					)
					NavigationLink(value: GoalFormDestination.progressUnit) {
						HStack {
							Text(.commonUnit)
								.foregroundStyle(.primary)
							Spacer()
							if let selectedUnit = formState.progress.selectedUnit {
								Text(selectedUnit.title)
									.foregroundStyle(.secondary)
							} else {
								Text(.commonNone)
									.foregroundStyle(.secondary)
							}
						}
					}
				}
			} header: {
				Text(.commonProgress)
			} footer: {
				Text(.goalFormProgressFooter)
					.font(.footnote)
			}
		}
		.scrollDismissesKeyboard(.interactively)
		.navigationTitle(mode.title)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				Button(.commonCancel, systemImage: "xmark") {
					if formState.hasChanges {
						isShowingConfirmation = true
					} else {
						dismiss()
					}
				}
				.confirmationDialog(
					.goalFormDismissConfirmationTitle,
					isPresented: $isShowingConfirmation
				) {
					Button(.goalFormDiscardChangesButton, role: .destructive) {
						dismiss()
					}
				} message: {
					Text(discardConfirmationMessage)
				}
			}
			ToolbarItem(placement: .confirmationAction) {
				Button(.commonSave, systemImage: "checkmark", action: save)
					.buttonStyle(.glassProminent)
					.disabled(formState.isSaveDisabled)
			}
		}
		.onChange(of: formState.schedule.hasTargetDate) {
			isTextInputFocused = false
		}
		.onChange(of: formState.progress.isProgressBased) {
			isTextInputFocused = false
		}
		.navigationDestination(for: GoalFormDestination.self) { destination in
			switch destination {
			case .tags:
				TagSelectionView(tagSelections: $formState.tagSelections)
			case .progressUnit:
				ProgressUnitSelectionView(selectedUnit: $formState.progress.selectedUnit)
			}
		}
		.goalSaveFailureAlert(failure: $saveFailure)
	}

	private func save() {
		guard !formState.isSaveDisabled else {
			return
		}
		do {
			try onSave(formState.makeFormData())
			dismiss()
		} catch {
			saveFailure = formState.saveFailureKind
		}
	}

	private func hasSelectedTags(in tagSelections: [GoalFormTagSelection]) -> Bool {
		tagSelections.contains { tagSelection in
			tagSelection.isSelected
		}
	}

	private func tagSelectionSummary(for tagSelections: [GoalFormTagSelection]) -> LocalizedStringResource {
		let selectedTagCount =
			tagSelections.filter { tagSelection in
				tagSelection.isSelected
			}
			.count
		return .goalFormTagSelectionSummary(selectedTagCount)
	}

	private var discardConfirmationMessage: String {
		switch mode {
		case .create:
			"Are you sure you want to discard this new goal?"
		case .edit:
			"Are you sure you want to discard your changes?"
		}
	}
}

// MARK: - Previews

#Preview("Create") {
	NavigationStack {
		GoalFormView(mode: .create) { _ in }
	}
}

#Preview("Edit") {
	NavigationStack {
		GoalFormView(
			mode: .edit(
				GoalFormData(
					name: "Workout 10 times",
					details: "Move a little every day.",
					targetDate: Date(),
					progress: .measurable(currentValue: 3, targetValue: 10, step: 2),
				),
			),
		) { _ in }
	}
}
