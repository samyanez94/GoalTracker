//
//  ProgressUnitSelectionView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/9/26.
//

import SwiftUI

struct ProgressUnitSelectionView: View {
  private enum Destination: Hashable {
    case customUnit
  }

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
        unitButton(title: "None", unit: nil)
      }
      ForEach(GoalProgressUnit.presetSections) { section in
        Section(section.title) {
          ForEach(section.units) { unit in
            unitButton(title: unit.title, unit: unit)
          }
        }
      }
      Section {
        NavigationLink(value: Destination.customUnit) {
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
    .navigationDestination(for: Destination.self) { destination in
      switch destination {
      case .customUnit:
        CustomUnitFormView(initialUnit: customUnit) { unit in
          customUnit = unit
          selectedUnit = unit
        }
      }
    }
  }

  private func unitButton(
    title: String,
    unit: GoalProgressUnit?,
  ) -> some View {
    Button {
      selectedUnit = unit
      dismiss()
    } label: {
      HStack {
        Text(title)
        Spacer()
        if selectedUnit == unit {
          Image(systemName: "checkmark")
            .foregroundStyle(.blue)
        }
      }
    }
    .foregroundStyle(.primary)
  }
}
