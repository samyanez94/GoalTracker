//
//  ProgressUnitButton.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct ProgressUnitButton: View {
	let title: String
	let unit: GoalProgressUnit?
	@Binding var selectedUnit: GoalProgressUnit?
	let onSelect: () -> Void

	init(
		title: String,
		unit: GoalProgressUnit?,
		selectedUnit: Binding<GoalProgressUnit?>,
		onSelect: @escaping () -> Void,
	) {
		self.title = title
		self.unit = unit
		_selectedUnit = selectedUnit
		self.onSelect = onSelect
	}

	init(
		title: LocalizedStringResource,
		unit: GoalProgressUnit?,
		selectedUnit: Binding<GoalProgressUnit?>,
		onSelect: @escaping () -> Void,
	) {
		self.init(
			title: String(localized: title),
			unit: unit,
			selectedUnit: selectedUnit,
			onSelect: onSelect,
		)
	}

	var body: some View {
		Button {
			selectedUnit = unit
			onSelect()
		} label: {
			HStack {
				Text(title)
				Spacer()
				if selectedUnit == unit {
					Image(systemName: "checkmark")
						.foregroundStyle(Color.accentColor)
						.accessibilityHidden(true)
				}
			}
		}
		.foregroundStyle(.primary)
		.accessibilityAddTraits(selectedUnit == unit ? .isSelected : [])
	}
}
