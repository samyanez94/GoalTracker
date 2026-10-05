//
//  GoalDeleteConfirmationDialog.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/1/26.
//

import SwiftUI

// MARK: - GoalDeleteConfirmationDialog

struct GoalDeleteConfirmationDialog: ViewModifier {
	@Binding var isPresented: Bool

	let goalCount: Int
	let onDelete: () -> Void

	func body(content: Content) -> some View {
		content.confirmationDialog(
			title,
			isPresented: $isPresented,
			titleVisibility: .visible,
		) {
			Button(buttonTitle, role: .destructive, action: onDelete)
		}
	}

	private var title: LocalizedStringResource {
		goalCount == 1
			? .goalDeleteConfirmationTitleSingle
			: .goalDeleteConfirmationTitleMultiple
	}

	private var buttonTitle: LocalizedStringResource {
		goalCount == 1 ? .commonDeleteGoal : .commonDeleteGoals
	}
}

// MARK: - View+GoalDeleteConfirmationDialog

extension View {
	func goalDeleteConfirmationDialog(
		isPresented: Binding<Bool>,
		goalCount: Int,
		onDelete: @escaping () -> Void,
	) -> some View {
		modifier(
			GoalDeleteConfirmationDialog(
				isPresented: isPresented,
				goalCount: goalCount,
				onDelete: onDelete,
			)
		)
	}
}
