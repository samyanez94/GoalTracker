//
//  GoalDetailCircularProgressView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/27/26.
//

import SwiftUI

// MARK: - GoalDetailCircularProgressView

struct GoalDetailCircularProgressView: View {
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	@State private var displayedProgress = 0.0

	let progress: Double
	let color: Color = .accentColor
	let size: CGFloat = 96
	let lineWidth: CGFloat = 15

	private var clampedProgress: Double {
		min(max(progress, 0), 1)
	}

	private var percentageText: String {
		clampedProgress.formatted(.percent.precision(.fractionLength(0)))
	}

	private var renderedProgress: Double {
		reduceMotion ? clampedProgress : displayedProgress
	}

	private var progressAnimation: Animation? {
		reduceMotion ? nil : .spring(.smooth, blendDuration: 0.5)
	}

	private var endColor: Color {
		color.mix(with: .white, by: 0.5)
	}

	private var backgroundColor: Color {
		color.opacity(0.15)
	}

	private var ringSide: CGFloat {
		max(size - lineWidth, 0)
	}

	private var capOffset: CGFloat {
		-ringSide / 2
	}

	var body: some View {
		ZStack {
			ZStack {
				Circle()
					.stroke(backgroundColor, lineWidth: lineWidth)
				Circle()
					.trim(from: 0, to: renderedProgress)
					.stroke(
						AngularGradient(
							gradient: Gradient(colors: [color, endColor]),
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
					.foregroundStyle(color)
					.offset(y: capOffset)
				CompletionCap(
					progress: renderedProgress,
					color: endColor,
					diameter: lineWidth,
					verticalOffset: capOffset,
				)
			}
			.frame(width: ringSide, height: ringSide, alignment: .center)
			Text(percentageText)
				.bold()
				.lineLimit(1)
				.minimumScaleFactor(0.75)
				.monospacedDigit()
				.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
		}
		.frame(width: size, height: size, alignment: .center)
		.animation(progressAnimation, value: displayedProgress)
		.task(id: clampedProgress) {
			displayedProgress = clampedProgress
		}
	}

	// MARK: - CompletionCap

	private struct CompletionCap: View {
		let progress: Double
		let color: Color
		let diameter: CGFloat
		let verticalOffset: CGFloat

		private var isVisible: Bool {
			progress > 0.95
		}

		private var shadowColor: Color {
			isVisible ? .black.opacity(0.1) : .clear
		}

		var body: some View {
			Circle()
				.frame(width: diameter, height: diameter)
				.foregroundStyle(color)
				.opacity(isVisible ? 1 : 0)
				.offset(y: verticalOffset)
				.rotationEffect(.degrees(360 * progress))
				.shadow(
					color: shadowColor,
					radius: 4,
					x: 4,
					y: 0,
				)
		}
	}
}

// MARK: - Previews

#Preview("Goal Progress Ring") {
	HStack(spacing: 24) {
		GoalDetailCircularProgressView(progress: 0)
		GoalDetailCircularProgressView(progress: 0.25)
		GoalDetailCircularProgressView(progress: 1)
	}
	.padding()
}
