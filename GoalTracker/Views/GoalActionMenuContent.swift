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
		Button("Edit", systemImage: "pencil", action: edit)
		Button(
			isCompleted ? "Mark as Pending" : "Mark as Completed",
			systemImage: isCompleted ? "circle" : "checkmark.circle",
			action: toggleCompletion,
		)
		Button("Delete", systemImage: "trash", role: .destructive, action: delete)
	}
}
