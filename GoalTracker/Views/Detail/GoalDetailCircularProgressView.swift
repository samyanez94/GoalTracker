//
//  GoalDetailCircularProgressView.swift
//  GoalTracker
//
//  Created by Codex on 5/27/26.
//

import SwiftUI

struct GoalDetailCircularProgressView: View {
    
    @State private var displayedProgress = 0.0

    let progress: Double

    let color: Color = .blue

    let lineWidth: CGFloat = 15

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var percentageText: String {
        clampedProgress.formatted(.percent.precision(.fractionLength(0)))
    }

    private var startColor: Color {
        color.mix(with: .white, by: 0.5)
    }

    private var backgroundColor: Color {
        color.opacity(0.15)
    }

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let ringSide = max(side - lineWidth, 0)
            ZStack {
                ZStack {
                    Circle()
                        .stroke(backgroundColor, lineWidth: lineWidth)
                    Circle()
                        .trim(from: 0, to: displayedProgress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [startColor, color]),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360),
                            ),
                            style: StrokeStyle(
                                lineWidth: lineWidth,
                                lineCap: .round,
                            ),
                        )
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .frame(width: lineWidth, height: lineWidth)
                        .foregroundStyle(startColor)
                        .offset(y: -ringSide / 2)
                }
                .frame(width: ringSide, height: ringSide, alignment: .center)
                Text(percentageText)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .monospacedDigit()
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .center,
            )
            .animation(.spring(.smooth, blendDuration: 0.5), value: displayedProgress)
            .task(id: clampedProgress) {
                displayedProgress = clampedProgress
            }
        }
    }
}

#Preview("Goal Progress Ring") {
    HStack(spacing: 24) {
        GoalDetailCircularProgressView(progress: 0)
        GoalDetailCircularProgressView(progress: 0.25)
        GoalDetailCircularProgressView(progress: 1)
    }
    .padding()
}
