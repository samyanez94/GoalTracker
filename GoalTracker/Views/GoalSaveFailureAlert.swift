//
//  GoalSaveFailureAlert.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

import SwiftUI

enum GoalSaveFailure: String, Identifiable {
    case addGoal
    case updateGoal
    case deleteGoal
    case updateProgress

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .addGoal, .updateGoal:
            "Couldn't Save Goal"
        case .deleteGoal:
            "Couldn't Delete Goal"
        case .updateProgress:
            "Couldn't Update Goal"
        }
    }

    var message: String {
        switch self {
        case .addGoal, .updateGoal:
            "Your changes weren't saved. Please try again."
        case .deleteGoal:
            "The goal wasn't deleted. Please try again."
        case .updateProgress:
            "Your progress change wasn't saved. Please try again."
        }
    }
}

struct GoalSaveFailureAlertModifier: ViewModifier {
    @Binding var failure: GoalSaveFailure?

    func body(content: Content) -> some View {
        content.alert(item: $failure) { failure in
            Alert(
                title: Text(failure.title),
                message: Text(failure.message),
                dismissButton: .default(Text("OK")),
            )
        }
    }
}

extension View {
    func goalSaveFailureAlert(
        failure: Binding<GoalSaveFailure?>,
    ) -> some View {
        modifier(GoalSaveFailureAlertModifier(failure: failure))
    }
}
