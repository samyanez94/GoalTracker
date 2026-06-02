//
//  TagChip.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/19/26.
//

import SwiftUI

struct TagChip: View {
	let name: String
	let isSelected: Bool
	var isEnabled = true
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			Text("#\(name)")
				.font(.subheadline.bold())
				.foregroundStyle(isSelected ? .white : .secondary)
				.padding(.horizontal, 12)
				.padding(.vertical, 8)
				.background(isSelected ? Color.accentColor : .gray.opacity(0.12))
				.clipShape(.capsule)
		}
		.buttonStyle(.plain)
		.allowsHitTesting(isEnabled)
	}
}
