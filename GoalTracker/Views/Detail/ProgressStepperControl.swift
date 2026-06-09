//
//  ProgressStepperControl.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

// MARK: - ProgressStepperControl

struct ProgressStepperControl: View {
	let canDecrement: Bool
	let canIncrement: Bool
	let onDecrement: () -> Void
	let onIncrement: () -> Void

	var body: some View {
		HStack(spacing: 12) {
			StepperButton(
				systemName: "minus",
				accessibilityLabel: "Decrease progress",
				action: onDecrement,
			)
			.disabled(!canDecrement)
			StepperButton(
				systemName: "plus",
				accessibilityLabel: "Increase progress",
				action: onIncrement,
			)
			.disabled(!canIncrement)
		}
		.frame(height: 48)
	}

	// MARK: - StepperButton

	struct StepperButton: View {
		let systemName: String
		let accessibilityLabel: String
		let action: () -> Void

		var body: some View {
			Button(action: action) {
				Label(accessibilityLabel, systemImage: systemName)
					.fontWeight(.semibold)
					.labelStyle(.iconOnly)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
			.buttonSizing(.flexible)
			.buttonStyle(.glassProminent)
		}
	}
}

// MARK: - Previews

#Preview("Enabled") {
	ProgressStepperControl(
		canDecrement: true,
		canIncrement: true,
		onDecrement: {},
		onIncrement: {},
	)
}

#Preview("At minimum") {
	ProgressStepperControl(
		canDecrement: false,
		canIncrement: true,
		onDecrement: {},
		onIncrement: {},
	)
}

#Preview("At maximum") {
	ProgressStepperControl(
		canDecrement: true,
		canIncrement: false,
		onDecrement: {},
		onIncrement: {},
	)
}
