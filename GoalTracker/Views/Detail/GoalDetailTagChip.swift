//
//  GoalDetailTagChip.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/23/26.
//

import SwiftUI

struct GoalDetailTagChip: View {
	let tag: Tag

	var body: some View {
		Text(verbatim: "#\(tag.name)")
			.font(.subheadline.bold())
			.foregroundStyle(.white)
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
			.background(Color.accentColor)
			.clipShape(.capsule)
	}
}
