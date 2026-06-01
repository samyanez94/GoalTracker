//
//  GoalDeleteConfirmationDialog.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/1/26.
//

import SwiftUI

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

	private var title: String {
		goalCount == 1
			? "Are you sure you want to delete this goal?"
			: "Are you sure you want to delete these goals?"
	}

	private var buttonTitle: String {
		goalCount == 1 ? "Delete Goal" : "Delete Goals"
	}
}

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
