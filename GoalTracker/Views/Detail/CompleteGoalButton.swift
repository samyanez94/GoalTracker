//
//  CompleteGoalButton.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct CompleteGoalButton: View {
	let isCompleted: Bool
	let action: () -> Void

	var body: some View {
		Button(title, action: action)
			.font(.headline)
			.controlSize(.large)
			.buttonSizing(.flexible)
			.buttonStyle(.glassProminent)
			.disabled(isCompleted)
			.padding(.horizontal)
	}

	private var title: LocalizedStringResource {
		isCompleted ? .detailCompleteGoalButtonCompleted : .detailCompleteGoalButtonComplete
	}
}
