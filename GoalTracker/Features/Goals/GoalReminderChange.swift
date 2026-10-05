//
//  GoalReminderChange.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 10/5/26.
//  Copyright © 2026 Samuel Yanez. All rights reserved.
//

/// Why a saved goal needs its reminders updated.
enum GoalReminderChange {
	case detailsSaved
	case progressSaved
	case reminderDisabled
}
