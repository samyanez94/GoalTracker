//
//  GoalProgressEventDeleteConfirmationDialog.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/4/26.
//

import SwiftUI

// MARK: - GoalProgressEventDeleteConfirmationDialog

struct GoalProgressEventDeleteConfirmationDialog: ViewModifier {
	@Binding var isPresented: Bool

	let eventCount: Int
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
		eventCount == 1
			? .progressEventDeleteConfirmationTitleSingle
			: .progressEventDeleteConfirmationTitleMultiple
	}

	private var buttonTitle: LocalizedStringResource {
		eventCount == 1 ? .commonDeleteEvent : .commonDeleteEvents
	}
}

// MARK: - View+GoalProgressEventDeleteConfirmationDialog

extension View {
	func goalProgressEventDeleteConfirmationDialog(
		isPresented: Binding<Bool>,
		eventCount: Int,
		onDelete: @escaping () -> Void,
	) -> some View {
		modifier(
			GoalProgressEventDeleteConfirmationDialog(
				isPresented: isPresented,
				eventCount: eventCount,
				onDelete: onDelete,
			)
		)
	}
}
