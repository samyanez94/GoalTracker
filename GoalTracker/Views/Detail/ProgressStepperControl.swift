//
//  ProgressStepperControl.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct ProgressStepperControl: View {
    let canDecrement: Bool
    let canIncrement: Bool
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RepeatingStepperButton(
                systemName: "minus",
                accessibilityLabel: "Decrease progress",
                action: onDecrement,
            )
            .disabled(!canDecrement)
            RepeatingStepperButton(
                systemName: "plus",
                accessibilityLabel: "Increase progress",
                action: onIncrement,
            )
            .disabled(!canIncrement)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
