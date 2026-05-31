//
//  GoalRecurrencePickerRow.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/28/26.
//

import SwiftUI

struct GoalRecurrencePickerRow: View {
	@Binding var recurrence: GoalRecurrence?

	var body: some View {
		Picker(selection: $recurrence) {
			Text("Never")
				.tag(nil as GoalRecurrence?)
			Divider()
			ForEach(GoalRecurrenceCadence.builtInOptions, id: \.self) { cadence in
				Text(cadence.displayTitle)
					.tag(GoalRecurrence(cadence: cadence) as GoalRecurrence?)
			}
		} label: {
			Label {
				Text("Repeat")
			} icon: {
				Image(systemName: "repeat")
					.foregroundStyle(.secondary)
			}
		}
	}
}
