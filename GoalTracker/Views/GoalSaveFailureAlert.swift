//
//  GoalSaveFailureAlert.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import SwiftUI

// MARK: - GoalSaveFailure

enum GoalSaveFailure: String, Identifiable {
	case addGoal
	case updateGoal
	case deleteGoal
	case deleteTag
	case updateProgress

	var id: Self {
		self
	}

	var title: LocalizedStringResource {
		switch self {
		case .addGoal, .updateGoal:
			.goalFailureAddOrUpdateTitle
		case .deleteGoal:
			.goalFailureDeleteGoalTitle
		case .deleteTag:
			.goalFailureDeleteTagTitle
		case .updateProgress:
			.goalFailureUpdateProgressTitle
		}
	}

	var message: LocalizedStringResource {
		switch self {
		case .addGoal, .updateGoal:
			.goalFailureAddOrUpdateMessage
		case .deleteGoal:
			.goalFailureDeleteGoalMessage
		case .deleteTag:
			.goalFailureDeleteTagMessage
		case .updateProgress:
			.goalFailureUpdateProgressMessage
		}
	}
}

// MARK: - GoalSaveFailureAlertModifier

struct GoalSaveFailureAlertModifier: ViewModifier {
	@Binding var failure: GoalSaveFailure?

	func body(content: Content) -> some View {
		content.alert(item: $failure) { failure in
			Alert(
				title: Text(failure.title),
				message: Text(failure.message),
				dismissButton: .default(Text(.commonOk)),
			)
		}
	}
}

// MARK: - View+GoalSaveFailureAlert

extension View {
	func goalSaveFailureAlert(
		failure: Binding<GoalSaveFailure?>,
	) -> some View {
		modifier(GoalSaveFailureAlertModifier(failure: failure))
	}
}
