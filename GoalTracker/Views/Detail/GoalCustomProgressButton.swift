//
//  GoalCustomProgressButton.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/30/26.
//

import SwiftUI

struct UpdateProgressButton: View {

	let action: () -> Void

	var body: some View {
		Button("Update progress", systemImage: "plus.forwardslash.minus", action: action)
			.fontWeight(.semibold)
			.labelStyle(.iconOnly)
			.controlSize(.large)
			.buttonStyle(.glassProminent)
			.buttonBorderShape(.circle)
	}
}
