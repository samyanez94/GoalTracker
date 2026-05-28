//
//  GoalReminderPickerRow.swift
//  GoalTracker
//
//  Created by Codex on 5/21/26.
//

import SwiftUI

struct GoalReminderPickerRow: View {
    @Binding var earlyReminder: GoalReminder?

    var body: some View {
        Picker(selection: $earlyReminder) {
            Text("None")
                .tag(nil as GoalReminder?)
            Divider()
            ForEach(GoalReminderPreset.allCases) { preset in
                Text(preset.title)
                    .tag(preset.earlyReminder as GoalReminder?)
            }
        } label: {
            Label {
                Text("Early Reminder")
            } icon: {
                Image(systemName: "bell")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
