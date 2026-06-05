//
//  GoalUnavailableView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/5/26.
//

import SwiftUI

// MARK: - GoalUnavailableView

struct GoalUnavailableView: View {
	let title: String
	let systemImage: String?
	let description: String?

	private let backgroundStyle: AnyShapeStyle?

	init(
		_ title: String,
		systemImage: String? = nil,
		description: String? = nil,
		backgroundStyle: AnyShapeStyle? = nil
	) {
		self.title = title
		self.systemImage = systemImage
		self.description = description
		self.backgroundStyle = backgroundStyle
	}

	var body: some View {
		ContentUnavailableView {
			if let systemImage {
				Label(title, systemImage: systemImage)
			} else {
                Text(title).bold()
			}
		} description: {
			if let description {
				Text(description)
			}
		}
		.optionalBackground(backgroundStyle)
	}
}

// MARK: - GoalUnavailableView+Helpers

extension GoalUnavailableView {
    
	private static var groupedBackgroundStyle: AnyShapeStyle {
		AnyShapeStyle(Color(.systemGroupedBackground))
	}

	static func emptyGoals(backgroundStyle: AnyShapeStyle? = groupedBackgroundStyle) -> Self {
		Self(
			"No goals",
			description: "Create your first goal to start tracking progress.",
			backgroundStyle: backgroundStyle
		)
	}

	static func emptySearch(backgroundStyle: AnyShapeStyle? = groupedBackgroundStyle) -> Self {
		Self(
			"No matching goals",
			systemImage: "magnifyingglass",
			description: "Check the spelling or try a new search.",
			backgroundStyle: backgroundStyle
		)
	}

	static func emptyPendingGoals(backgroundStyle: AnyShapeStyle? = groupedBackgroundStyle) -> Self {
		Self(
			"No pending goals",
			systemImage: "checkmark.circle",
			description: "Show completed goals to see what you've finished.",
			backgroundStyle: backgroundStyle
		)
	}

	static func goalNotFound(backgroundStyle: AnyShapeStyle? = nil) -> Self {
		Self(
			"Goal Not Found",
			systemImage: "exclamationmark.triangle",
			description: "This goal may have been deleted.",
			backgroundStyle: backgroundStyle
		)
	}
}

private extension View {
	@ViewBuilder
	func optionalBackground(_ style: AnyShapeStyle?) -> some View {
		if let style {
			background(style)
		} else {
			self
		}
	}
}
