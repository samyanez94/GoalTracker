//
//  CollapsibleSectionHeader.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct CollapsibleSectionHeader: View {
	let title: String

	@Binding var isExpanded: Bool

	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	var body: some View {
		Button {
			toggleExpansion()
		} label: {
			HStack(spacing: 8) {
				Text(title)
					.font(.title3.bold())
				Image(systemName: "chevron.right")
					.font(.caption.bold())
					.rotationEffect(.degrees(isExpanded ? 90 : 0))
					.animation(expansionAnimation, value: isExpanded)
				Spacer()
			}
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
		.accessibilityLabel(title)
		.accessibilityValue(
			isExpanded
				? Text(.accessibilityCollapsibleSectionExpanded)
				: Text(.accessibilityCollapsibleSectionCollapsed)
		)
		.accessibilityHint(Text(.accessibilityCollapsibleSectionHint))
		.accessibilityAddTraits(.isHeader)
	}

	private var expansionAnimation: Animation? {
		reduceMotion ? nil : .smooth
	}

	private func toggleExpansion() {
		if reduceMotion {
			isExpanded.toggle()
		} else {
			withAnimation(.smooth) {
				isExpanded.toggle()
			}
		}
	}
}
