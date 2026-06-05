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
			Label("Moku Couldn't Open Your Data", systemImage: "externaldrive.badge.exclamationmark")
		} description: {
			Text("Try again. If the problem continues, share the diagnostic details so we can help.")
		}
		.safeAreaInset(edge: .bottom) {
			VStack {
				Button("Try Again", action: retry)
					.buttonStyle(.borderedProminent)
                    .buttonSizing(.flexible)
                    .controlSize(.large)
				ShareLink(item: failure.diagnosticDetails) {
					Text("Share Diagnostic Details")
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

private enum PreviewError: LocalizedError {
	case failed

	var errorDescription: String? {
		"The model container could not be loaded."
	}
}
