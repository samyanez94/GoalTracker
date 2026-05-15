//
//  AddGoalButton.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct AddGoalButton: View {
    let action: @MainActor () -> Void

    @State private var feedbackTrigger = false

    var body: some View {
        Button {
            feedbackTrigger.toggle()
            action()
        } label: {
            Label("Add Goal", systemImage: "plus")
                .font(.title2.bold())
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
        }
        .tint(.blue)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .shadow(
            color: .black.opacity(0.16),
            radius: 12, x: 0, y: 6,
        )
        .sensoryFeedback(.impact(weight: .light), trigger: feedbackTrigger)
    }
}
