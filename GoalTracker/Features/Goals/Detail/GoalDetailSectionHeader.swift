//
//  GoalDetailSectionHeader.swift
//  GoalTracker
//
//  Created by Codex on 6/11/26.
//

import SwiftUI

struct GoalDetailSectionHeader: View {
	let title: LocalizedStringResource

	var body: some View {
		Text(title)
			.font(.headline.bold())
			.foregroundStyle(.secondary)
			.accessibilityAddTraits(.isHeader)
	}
}
