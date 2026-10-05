//
//  GoalDetailCard.swift
//  GoalTracker
//
//  Created by Codex on 6/11/26.
//

import SwiftUI

struct GoalDetailCard<Content: View>: View {
	let content: Content

	init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}

	var body: some View {
		content
			.padding(.all, 16)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(
				Color(.secondarySystemGroupedBackground),
				in: .rect(cornerRadius: 24, style: .continuous),
			)
	}
}
