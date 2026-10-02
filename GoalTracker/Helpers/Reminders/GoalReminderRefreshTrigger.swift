/// Restarts reconciliation on foreground entry or changes to synced reminder data.
struct GoalReminderRefreshTrigger: Equatable {
	let isActive: Bool
	let states: [GoalReminderSyncState]
}
