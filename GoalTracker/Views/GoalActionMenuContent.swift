//
//  GoalActionMenuContent.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/27/26.
//

import SwiftUI

struct GoalActionMenuContent: View {
	let isCompleted: Bool
	let edit: () -> Void
	let toggleCompletion: () -> Void
	let delete: () -> Void

	var body: some View {
		Button(.goalActionEdit, systemImage: "pencil", action: edit)
		Button(
			toggleCompletionTitle,
			systemImage: isCompleted ? "circle" : "checkmark.circle",
			action: toggleCompletion,
		)
		Button(.commonDelete, systemImage: "trash", role: .destructive, action: delete)
	}

	private var toggleCompletionTitle: LocalizedStringResource {
		isCompleted ? .goalActionMarkAsPending : .goalActionMarkAsCompleted
	}
}
