//
//  GoalProgressUpdateView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/30/26.
//

import SwiftData
import SwiftUI

// MARK: - GoalProgressUpdateView

struct GoalProgressUpdateView: View {
	@Environment(\.dismiss) private var dismiss

	@Environment(\.modelContext) private var modelContext

	let goal: Goal

	@FocusState private var isProgressFieldFocused: Bool

	@State private var progressAmount: Double?

	@State private var saveFailure: GoalSaveFailure?

	var body: some View {
		VStack(spacing: 8) {
			TextField("0", value: $progressAmount, format: .number.sign(strategy: .automatic))
				.focused($isProgressFieldFocused)
				.tint(.clear)
				.keyboardType(.decimalPad)
				.font(.system(size: 72, weight: .bold))
				.multilineTextAlignment(.center)
				.textFieldStyle(.plain)
			if let unitTitle {
				Text(unitTitle)
					.font(.title3)
					.foregroundStyle(.secondary)
			}
		}
		.frame(maxWidth: .infinity)
		.padding()
		.navigationTitle(progressAmountTitle)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				Button("Cancel", systemImage: "xmark") {
					dismiss()
				}
			}
			ToolbarItem(placement: .confirmationAction) {
				Button("Save", systemImage: "checkmark") {
					saveProgressUpdate()
				}
				.buttonStyle(.glassProminent)
				.disabled(isSaveDisabled)
			}
			ToolbarItemGroup(placement: .keyboard) {
				Button(
					"Toggle Sign",
					systemImage: "plus.forwardslash.minus",
					action: toggleSign
				)
				Spacer()
			}
		}
		.onAppear {
			isProgressFieldFocused = true
		}
		.goalSaveFailureAlert(failure: $saveFailure)
	}

	private var unitTitle: String? {
		guard case .measurable(let progress) = goal.progress,
			let unit = progress.unit
		else {
			return nil
		}
		return unit.title.capitalized
	}

	private var isSaveDisabled: Bool {
		guard let progressAmount else {
			return true
		}
		guard progressAmount != 0 else {
			return true
		}
		return false
	}

	private var progressAmountTitle: String {
		guard let progressAmount, progressAmount < 0 else {
			return "Increase Progress"
		}
		return "Decrease Progress"
	}

	private var goalManager: GoalManager {
		GoalManager(modelContext: modelContext)
	}

	private func toggleSign() {
		guard let progressAmount else {
			return
		}
		self.progressAmount = -progressAmount
	}

	private func saveProgressUpdate() {
		guard let progressAmount else {
			return
		}
		do {
			try goalManager.updateProgress(goal, by: progressAmount)
			dismiss()
		} catch {
			saveFailure = .updateProgress
		}
	}
}

// MARK: - Previews

#Preview("Update Progress") {
	NavigationStack {
		GoalProgressUpdateView(
			goal: Goal(
				name: "Read 2 books",
				details: nil,
				createdAt: Date(),
				progress: .measurable(
					currentValue: 1,
					targetValue: 2,
					unit: .custom(
						title: "Books",
						abbreviatedTitle: "books",
					),
				),
			)
		)
	}
}
