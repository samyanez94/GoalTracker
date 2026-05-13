//
//  CircularGoalProgressView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct CircularGoalProgressView: View {
  let progress: Double

  private var clampedProgress: Double {
    min(max(progress, 0), 1)
  }

  var body: some View {
    ZStack {
      Circle()
        .stroke(.blue.opacity(0.25), lineWidth: 5)
      Circle()
        .trim(from: 0, to: clampedProgress)
        .stroke(
          .blue,
          style: StrokeStyle(
            lineWidth: 5,
            lineCap: .round,
          ),
        )
        .rotationEffect(.degrees(-90))
    }
    .accessibilityHidden(true)
  }
}
