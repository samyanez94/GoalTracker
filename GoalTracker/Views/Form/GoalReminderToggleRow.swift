//
//  GoalReminderToggleRow.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/21/26.
//

import SwiftUI

struct GoalReminderToggleRow: View {
	@Binding var reminder: GoalReminder?

	var body: some View {
		Toggle(isOn: reminderBinding) {
			Label {
				Text("Reminder")
			} icon: {
				Image(systemName: "bell").foregroundStyle(.secondary)
			}
		}
	}

	private var reminderBinding: Binding<Bool> {
		Binding {
			reminder != nil
		} set: { isEnabled in
			if isEnabled { reminder = GoalReminder() } else { reminder = nil }
		}
	}
}
