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
            .foregroundStyle(.blue)
        }
      }
    }
    .foregroundStyle(.primary)
  }
}
