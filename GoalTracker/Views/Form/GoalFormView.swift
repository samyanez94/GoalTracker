//
//  GoalFormView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/3/26.
//

import SwiftData
import SwiftUI

// MARK: - GoalFormMode

/// Describes whether the goal form should create a new goal or edit existing form data.
enum GoalFormMode {
	/// Creates an empty form for a new goal.
	case create

	/// Create a form with pre-filled values for editing.
	case edit(GoalFormData)

	var title: String {
		switch self {
		case .create:
			"New Goal"
		case .edit:
			"Edit Goal"
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

	@Environment(\.modelContext) private var modelContext

	@State private var formState: GoalFormState

	@FocusState private var isTextInputFocused: Bool

	@State private var isShowingConfirmation = false

	@State private var saveFailure: GoalSaveFailure?

	@State private var didSave = false

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
			Section("Details") {
				TextField("Goal name", text: $formState.name)
					.focused($isTextInputFocused)
				TextField(
					"Description",
					text: $formState.details,
					axis: .vertical,
				)
				.focused($isTextInputFocused)
				.lineLimit(1...6)
			}
			Section {
				NavigationLink(value: GoalFormDestination.tags) {
					HStack {
						Label {
							Text("Tags")
						} icon: {
							Image(systemName: "number")
								.foregroundStyle(.secondary)
						}
						Spacer()
						if formState.selectedTags.isEmpty == false {
							Text(tagSelectionSummary(for: formState.selectedTags))
								.foregroundStyle(.secondary)
						}
					}
				}
			} header: {
				Text("Organization")
			} footer: {
				Text("Use tags to group related goals.")
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
			Section {
				GoalRecurrencePickerRow(recurrence: $formState.recurrence)
				if formState.recurrence != nil {
					GoalReminderToggleRow(reminder: $formState.reminder)
				}
			} header: {
				Text("Recurrence")
			} footer: {
				Text(
					"Use recurring goals for habits and goals you want to repeat over time. Turn on reminders to get a notification at 9 AM on the first day of each repeat."
				)
				.font(.footnote)
				.foregroundStyle(.secondary)
			}
			if formState.allowsTargetDate {
				Section {
					HStack {
						TargetDateSummaryButton(
							hasTargetDate: formState.hasTargetDate,
							targetDate: formState.targetDate,
							action: {
								withAnimation {
									formState.toggleTargetDatePicker()
								}
							},
						)
						Toggle(
							"Target Date",
							isOn: $formState.hasTargetDate,
						)
						.labelsHidden()
					}
					if formState.hasTargetDate, formState.isTargetDatePickerExpanded {
						DatePicker(
							"Select target date",
							selection: $formState.targetDate,
							displayedComponents: .date,
						)
						.datePickerStyle(.graphical)
					}
					if formState.hasTargetDate {
						GoalReminderToggleRow(reminder: $formState.reminder)
					}
				} header: {
					Text("Date")
				} footer: {
					Text(
						"Set a target date to help you know when to complete this goal. Turn on reminders to get a notification at 9 AM that day."
					)
					.font(.footnote)
					.foregroundStyle(.secondary)
				}
			}
			Section {
				Toggle(isOn: $formState.isProgressBased) {
					Label {
						Text("Track progress")
					} icon: {
						Image(systemName: "plus.forwardslash.minus")
							.foregroundStyle(.secondary)
					}
				}
				if formState.isProgressBased {
					ProgressTextFieldRow(
						label: "Target Value",
						placeholder: "1",
						value: $formState.targetValue,
						focus: $isTextInputFocused,
					)
					ProgressTextFieldRow(
						label: "Step",
						placeholder: "1",
						value: $formState.step,
						focus: $isTextInputFocused,
					)
					NavigationLink(value: GoalFormDestination.progressUnit) {
						HStack {
							Text("Unit")
								.foregroundStyle(.primary)
							Spacer()
							Text(formState.selectedProgressUnit?.title ?? "None")
								.foregroundStyle(.secondary)
						}
					}
				}
			} header: {
				Text("Progress")
			} footer: {
				Text("Track progress toward a numeric target.")
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
		}
		.navigationTitle(mode.title)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				Button("Cancel", systemImage: "xmark") {
					if formState.hasChanges {
						isShowingConfirmation = true
					} else {
						dismiss()
					}
				}
				.confirmationDialog("Dismiss confirmation", isPresented: $isShowingConfirmation) {
					Button("Discard Changes", role: .destructive) {
						dismiss()
					}
				} message: {
					Text(discardConfirmationMessage)
				}
			}
			ToolbarItem(placement: .confirmationAction) {
				Button("Save", systemImage: "checkmark", action: save)
					.buttonStyle(.glassProminent)
					.disabled(formState.isSaveDisabled)
			}
		}
		.onChange(of: formState.hasTargetDate) { _, hasTargetDate in
			isTextInputFocused = false
			withAnimation {
				formState.setTargetDateEnabled(hasTargetDate)
			}
		}
		.onChange(of: formState.isProgressBased) {
			isTextInputFocused = false
		}
		.navigationDestination(for: GoalFormDestination.self) { destination in
			switch destination {
			case .tags:
				TagSelectionView(selectedTags: $formState.selectedTags)
			case .progressUnit:
				ProgressUnitSelectionView(selectedUnit: $formState.selectedProgressUnit)
			}
		}
		.onDisappear {
			deleteUnusedTags()
		}
		.goalSaveFailureAlert(failure: $saveFailure)
	}

	private func save() {
		guard !formState.isSaveDisabled else {
			return
		}
		do {
			try onSave(formState.makeFormData())
			didSave = true
			dismiss()
		} catch {
			saveFailure = formState.saveFailureKind
		}
	}

	private func deleteUnusedTags() {
		guard !didSave else {
			return
		}
		try? GoalManager(modelContext: modelContext).deleteUnusedTags()
	}

	private func tagSelectionSummary(for tags: [Tag]) -> String {
		"\(tags.count) Selected"
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
