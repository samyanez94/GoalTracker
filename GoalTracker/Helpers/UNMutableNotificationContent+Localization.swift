//
//  UNMutableNotificationContent+Localization.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/10/26.
//

import Foundation
import UserNotifications

// MARK: - UNMutableNotificationContent+Localization

extension UNMutableNotificationContent {
	convenience init(
		title: String,
		body: LocalizedStringResource,
		sound: UNNotificationSound? = .default,
		userInfo: [AnyHashable: Any] = [:],
	) {
		self.init()
		self.title = title
		self.body = String(localized: body)
		self.sound = sound
		self.userInfo = userInfo
	}

	convenience init(
		title: LocalizedStringResource,
		body: LocalizedStringResource,
		sound: UNNotificationSound? = .default,
		userInfo: [AnyHashable: Any] = [:],
	) {
		self.init(
			title: String(localized: title),
			body: body,
			sound: sound,
			userInfo: userInfo,
		)
	}
}
