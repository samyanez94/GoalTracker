//
//  GoalPersistenceRecoveryView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/5/26.
//

import SwiftUI

// MARK: - GoalPersistenceRecoveryView

struct GoalPersistenceRecoveryView: View {
	let failure: GoalTrackerPersistenceFailure
	let retry: () -> Void

	var body: some View {
		ContentUnavailableView {
			Label(
				.persistenceRecoveryTitle,
				systemImage: "externaldrive.badge.exclamationmark"
			)
		} description: {
			Text(.persistenceRecoveryDescription)
		}
		.safeAreaInset(edge: .bottom) {
			VStack {
				Button(.persistenceRecoveryTryAgain, action: retry)
					.buttonStyle(.borderedProminent)
					.buttonSizing(.flexible)
					.controlSize(.large)
				ShareLink(item: failure.diagnosticDetails) {
					Text(.persistenceRecoveryShareDiagnosticDetails)
				}
				.buttonStyle(.bordered)
				.buttonSizing(.flexible)
				.controlSize(.large)
			}
			.padding(.horizontal)
		}
	}
}

// MARK: - Previews

#Preview {
	GoalPersistenceRecoveryView(
		failure: GoalTrackerPersistenceFailure(error: PreviewError.failed),
		retry: {},
	)
}

#if DEBUG

// periphery:ignore
private enum PreviewError: LocalizedError {
	case failed

	var errorDescription: String? {
		"The model container could not be loaded."
	}
}

#endif
