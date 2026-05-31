//
//  ProgressUnitSelectionView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/9/26.
//

import SwiftUI

private enum ProgressUnitSelectionDestination: Hashable {
    case customUnit
}

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
            Section("None") {
                ProgressUnitButton(
                    title: "None",
                    unit: nil,
                    selectedUnit: $selectedUnit,
                ) {
                    dismiss()
                }
            }
            ForEach(GoalProgressUnit.presetSections) { section in
                Section(section.title) {
                    ForEach(section.units) { unit in
                        ProgressUnitButton(
                            title: unit.title,
                            unit: unit,
                            selectedUnit: $selectedUnit,
                        ) {
                            dismiss()
                        }
                    }
                }
            }
            Section {
                NavigationLink(value: ProgressUnitSelectionDestination.customUnit) {
                    HStack {
                        Text("Custom")
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
        .navigationTitle("Unit")
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
