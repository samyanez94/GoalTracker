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
		Button(action: action) {
			Label("Update progress", systemImage: "plus.forwardslash.minus", ).font(.title3.bold())
				.labelStyle(.iconOnly).frame(width: 38, height: 38)
		}
		.buttonStyle(.glassProminent).buttonBorderShape(.circle)
	}
}
