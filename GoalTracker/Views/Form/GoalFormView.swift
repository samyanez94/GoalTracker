//
//  GoalFormView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/3/26.
//

import SwiftData
import SwiftUI

enum GoalFormMode {
	case create
	case edit(GoalFormData)

	var title: String {
		switch self {
		case .create: "New Goal"
		case .edit: "Edit Goal"
		}
	}

	var initialData: GoalFormData {
		switch self {
		case .create: .empty
		case .edit(let data): data
		}
	}
}

private enum GoalFormDestination: Hashable {
	case tags
	case progressUnit
}

struct GoalFormView: View {
	@Environment(\.dismiss) private var dismiss

	@Environment(\.modelContext) private var modelContext

	@State private var model: GoalFormModel

	@FocusState private var isTextInputFocused: Bool

	@State private var showingConfirmation = false

	@State private var saveFailure: GoalSaveFailure?

	@State private var didSave = false

	private let mode: GoalFormMode

	private let onSave: (GoalFormData) throws -> Void

	init(mode: GoalFormMode, onSave: @escaping (GoalFormData) throws -> Void, ) {
		self.mode = mode
		self.onSave = onSave
		_model = State(initialValue: GoalFormModel(mode: mode))
	}

	var body: some View {
		// The view owns the form model with @State; @Bindable exposes bindings to its fields.
		@Bindable var model = model

		Form {
			Section("Details") {
				TextField("Goal name", text: $model.name).focused($isTextInputFocused)
				TextField("Description", text: $model.details, axis: .vertical, )
					.focused($isTextInputFocused).lineLimit(1...6)
			}
			Section {
				NavigationLink(value: GoalFormDestination.tags) {
					HStack {
						Label {
							Text("Tags")
						} icon: {
							Image(systemName: "number").foregroundStyle(.secondary)
						}
						Spacer()
						if model.selectedTags.isEmpty == false {
							Text(tagSelectionSummary(for: model.selectedTags))
								.foregroundStyle(.secondary)
						}
					}
				}
			} header: {
				Text("Organization")
			} footer: {
				Text("Use tags to group related goals.").font(.footnote).foregroundStyle(.secondary)
			}
			Section {
				GoalRecurrencePickerRow(recurrence: $model.recurrence)
				if model.recurrence != nil { GoalReminderToggleRow(reminder: $model.reminder) }
			} header: {
				Text("Recurrence")
			} footer: {
				Text(
					"Use recurring goals for habits and goals you want to repeat over time. Turn on reminders to get a notification at 9 AM on the first day of each repeat."
				)
				.font(.footnote).foregroundStyle(.secondary)
			}
			if model.allowsDueDate {
				Section {
					HStack {
						DueDateSummaryButton(
							hasDueDate: model.hasDueDate,
							dueDate: model.dueDate,
							action: { withAnimation { model.toggleDueDatePicker() } },
						)
						Toggle("Due Date", isOn: $model.hasDueDate, ).labelsHidden()
					}
					if model.hasDueDate, model.isDueDatePickerExpanded {
						DatePicker(
							"Select due date",
							selection: $model.dueDate,
							displayedComponents: .date,
						)
						.datePickerStyle(.graphical)
					}
					if model.hasDueDate { GoalReminderToggleRow(reminder: $model.reminder) }
				} header: {
					Text("Date")
				} footer: {
					Text(
						"Set a due date to help you know when to complete this goal. Turn on reminders to get a notification at 9 AM that day."
					)
					.font(.footnote).foregroundStyle(.secondary)
				}
			}
			Section {
				Toggle(isOn: $model.isProgressBased) {
					Label {
						Text("Track progress")
					} icon: {
						Image(systemName: "plus.forwardslash.minus").foregroundStyle(.secondary)
					}
				}
				if model.isProgressBased {
					ProgressTextFieldRow(
						label: "Target Value",
						placeholder: "1",
						value: $model.targetValue,
						focus: $isTextInputFocused,
					)
					ProgressTextFieldRow(
						label: "Step",
						placeholder: "1",
						value: $model.step,
						focus: $isTextInputFocused,
					)
					NavigationLink(value: GoalFormDestination.progressUnit) {
						HStack {
							Text("Unit").foregroundStyle(.primary)
							Spacer()
							Text(model.selectedProgressUnit?.title ?? "None")
								.foregroundStyle(.secondary)
						}
					}
				}
			} header: {
				Text("Progress")
			} footer: {
				Text("Track progress toward a numeric target.").font(.footnote)
					.foregroundStyle(.secondary)
			}
		}
		.navigationTitle(mode.title).navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				Button("Cancel", systemImage: "xmark") {
					if model.hasChanges { showingConfirmation = true } else { dismiss() }
				}
				.confirmationDialog("Dismiss confirmation", isPresented: $showingConfirmation) {
					Button("Discard Changes", role: .destructive) { dismiss() }
				} message: {
					Text(discardConfirmationMessage)
				}
			}
			ToolbarItem(placement: .confirmationAction) {
				Button("Save", systemImage: "checkmark", action: save).tint(.blue)
					.buttonStyle(.glassProminent).disabled(model.isSaveDisabled)
			}
		}
		.onChange(of: model.hasDueDate) { _, hasDueDate in
			isTextInputFocused = false
			withAnimation { model.setDueDateEnabled(hasDueDate) }
		}
		.onChange(of: model.isProgressBased) { isTextInputFocused = false }
		.navigationDestination(for: GoalFormDestination.self) { destination in
			switch destination {
			case .tags: TagSelectionView(selectedTags: $model.selectedTags)
			case .progressUnit: ProgressUnitSelectionView(selectedUnit: $model.selectedProgressUnit)
			}
		}
		.onDisappear { deleteUnusedTags() }.goalSaveFailureAlert(failure: $saveFailure)
	}

	private func save() {
		guard !model.isSaveDisabled else { return }
		do {
			try onSave(model.makeFormData())
			didSave = true
			dismiss()
		} catch { saveFailure = model.saveFailureKind }
	}

	private func deleteUnusedTags() {
		guard !didSave else { return }
		try? GoalManager(modelContext: modelContext).deleteUnusedTags()
	}

	private func tagSelectionSummary(for tags: [Tag]) -> String { "\(tags.count) Selected" }

	private var discardConfirmationMessage: String {
		switch mode {
		case .create: "Are you sure you want to discard this new goal?"
		case .edit: "Are you sure you want to discard your changes?"
		}
	}
}

#Preview("Create") { NavigationStack { GoalFormView(mode: .create) { _ in } } }

#Preview("Edit") {
	NavigationStack {
		GoalFormView(
			mode: .edit(
				GoalFormData(
					name: "Workout 10 times",
					details: "Move a little every day.",
					dueDate: Date(),
					progress: .measurable(currentValue: 3, targetValue: 10, step: 2),
				),
			),
		) { _ in }
	}
}
