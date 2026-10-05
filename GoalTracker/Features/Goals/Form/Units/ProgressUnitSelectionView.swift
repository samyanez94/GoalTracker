//
//  ProgressUnitSelectionView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/9/26.
//

import SwiftUI

// MARK: - ProgressUnitSelectionDestination

private enum ProgressUnitSelectionDestination: Hashable {
	case customUnit
}

// MARK: - ProgressUnitSelectionView

struct ProgressUnitSelectionView: View {
	@Environment(\.dismiss) private var dismiss

	@Binding var selectedUnit: GoalProgressUnit?

	@State private var customUnit: GoalProgressUnit?

	init(selectedUnit: Binding<GoalProgressUnit?>) {
		_selectedUnit = selectedUnit
		let initialUnit = selectedUnit.wrappedValue
		_customUnit = State(initialValue: initialUnit?.category == .custom ? initialUnit : nil)
	}

	var body: some View {
		List {
			Section {
				ProgressUnitButton(
					title: .commonNone,
					unit: nil,
					selectedUnit: $selectedUnit,
				) {
					dismiss()
				}
			} header: {
				Text(.commonNone)
					.font(.title3.bold())
			}
			ForEach(GoalProgressUnit.presetSections) { section in
				Section {
					ForEach(section.units) { unit in
						ProgressUnitButton(
							title: unit.title,
							unit: unit,
							selectedUnit: $selectedUnit,
						) {
							dismiss()
						}
					}
				} header: {
					Text(section.title)
						.font(.title3.bold())
				}
			}
			Section {
				NavigationLink(value: ProgressUnitSelectionDestination.customUnit) {
					HStack {
						Text(.commonCustom)
							.foregroundStyle(.primary)
						Spacer()
						if let customUnit {
							Text(customUnit.title)
								.foregroundStyle(.secondary)
						}
					}
				}
			}
		}
		.navigationTitle(.commonUnit)
		.navigationBarTitleDisplayMode(.inline)
		.navigationDestination(for: ProgressUnitSelectionDestination.self) { destination in
			switch destination {
			case .customUnit:
				CustomUnitFormView(initialUnit: customUnit) { unit in
					customUnit = unit
					selectedUnit = unit
				}
			}
		}
	}
}
