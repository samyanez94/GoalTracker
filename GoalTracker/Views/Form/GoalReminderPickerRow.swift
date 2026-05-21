//
//  GoalReminderPickerRow.swift
//  GoalTracker
//
//  Created by Codex on 5/21/26.
//

import SwiftUI

struct GoalReminderPickerRow: View {
    @Binding var reminder: GoalReminder?

    var body: some View {
        Picker("Reminder", selection: $reminder) {
            Text("None")
                .tag(nil as GoalReminder?)
            Divider()
            ForEach(GoalReminderPreset.allCases) { preset in
                Text(preset.title)
                    .tag(preset.reminder as GoalReminder?)
            }
        }
    }
}
