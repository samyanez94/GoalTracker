//
//  GoalDetailCircularProgressView.swift
//  GoalTracker
//
//  Created by Codex on 5/27/26.
//

import SwiftUI

struct GoalDetailCircularProgressView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var displayedProgress = 0.0

    let progress: Double

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var progressAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 1).delay(0.25)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.blue.opacity(0.25), lineWidth: 20)
            Circle()
                .trim(from: 0, to: displayedProgress)
                .stroke(
                    .blue,
                    style: StrokeStyle(
                        lineWidth: 20,
                        lineCap: .round,
                    ),
                )
                .rotationEffect(.degrees(-90))
        }
        .task(id: clampedProgress) {
            withAnimation(progressAnimation) {
                displayedProgress = clampedProgress
            }
        }
        .accessibilityHidden(true)
    }
}
