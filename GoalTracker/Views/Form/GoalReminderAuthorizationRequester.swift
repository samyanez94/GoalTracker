//
//  GoalReminderAuthorizationRequester.swift
//  GoalTracker
//
//  Created by Codex on 5/21/26.
//

import Foundation

@MainActor
enum GoalReminderAuthorizationRequester {
    static func requestAuthorizationIfNeeded(for data: GoalFormData) async {
        guard data.dueDate != nil, data.reminder != nil else {
            return
        }
        _ = try? await GoalNotificationScheduler().requestAuthorizationIfNeeded()
    }
}
