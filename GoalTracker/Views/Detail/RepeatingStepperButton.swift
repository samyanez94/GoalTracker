//
//  RepeatingStepperButton.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct RepeatingStepperButton: View {
  let systemName: String
  let accessibilityLabel: String
  let action: () -> Void

  @State private var repeatTask: Task<Void, Never>?

  var body: some View {
    Button(accessibilityLabel, systemImage: systemName, action: action)
      .font(.title3.weight(.semibold))
      .labelStyle(.iconOnly)
      .frame(maxWidth: .infinity)
      .frame(height: 44)
      .tint(.blue)
      .buttonStyle(.glassProminent)
      .buttonBorderShape(.capsule)
      .onLongPressGesture(
        minimumDuration: 0.35,
        perform: {},
        onPressingChanged: { isPressing in
          if isPressing {
            startRepeating()
          } else {
            stopRepeating()
          }
        },
      )
      .onDisappear {
        stopRepeating()
      }
  }

  private func startRepeating() {
    guard repeatTask == nil else {
      return
    }
    repeatTask = Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(350))
      while !Task.isCancelled {
        action()
        try? await Task.sleep(for: .milliseconds(120))
      }
    }
  }

  private func stopRepeating() {
    repeatTask?.cancel()
    repeatTask = nil
  }
}
