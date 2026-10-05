//
//  GoalUnavailableView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/5/26.
//

import SwiftUI

// MARK: - GoalUnavailableView

struct GoalUnavailableView: View {
	let title: LocalizedStringResource
	let systemImage: String?
	let description: LocalizedStringResource?

	private let backgroundStyle: AnyShapeStyle?

	init(
		_ title: LocalizedStringResource,
		systemImage: String? = nil,
		description: LocalizedStringResource? = nil,
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
			.goalUnavailableEmptyGoalsTitle,
			description: .goalUnavailableEmptyGoalsDescription,
			backgroundStyle: backgroundStyle
		)
	}

	static func emptySearch(backgroundStyle: AnyShapeStyle? = groupedBackgroundStyle) -> Self {
		Self(
			.goalUnavailableEmptySearchTitle,
			systemImage: "magnifyingglass",
			description: .goalUnavailableEmptySearchDescription,
			backgroundStyle: backgroundStyle
		)
	}

	static func emptyPendingGoals(backgroundStyle: AnyShapeStyle? = groupedBackgroundStyle) -> Self {
		Self(
			.goalUnavailableEmptyPendingGoalsTitle,
			systemImage: "checkmark.circle",
			description: .goalUnavailableEmptyPendingGoalsDescription,
			backgroundStyle: backgroundStyle
		)
	}

	static func emptyProgressEvents(backgroundStyle: AnyShapeStyle? = groupedBackgroundStyle) -> Self {
		Self(
			.progressEventListNoProgress,
			systemImage: "chart.line.uptrend.xyaxis",
			backgroundStyle: backgroundStyle
		)
	}

	static func goalNotFound(backgroundStyle: AnyShapeStyle? = nil) -> Self {
		Self(
			.goalUnavailableGoalNotFoundTitle,
			systemImage: "exclamationmark.triangle",
			description: .goalUnavailableGoalNotFoundDescription,
			backgroundStyle: backgroundStyle
		)
	}
}

extension View {
	@ViewBuilder
	fileprivate func optionalBackground(_ style: AnyShapeStyle?) -> some View {
		if let style {
			background(style)
		} else {
			self
		}
	}
}
