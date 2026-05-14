//
//  CompleteGoalButton.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct CompleteGoalButton: View {
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isCompleted ? "Completed" : "Complete")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(.glassProminent)
        .disabled(isCompleted)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
