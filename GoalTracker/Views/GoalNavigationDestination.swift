//
//  GoalNavigationDestination.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/4/26.
//

import Foundation

// MARK: - GoalNavigationDestination

enum GoalNavigationDestination: Hashable {
	case goal(UUID)
	case progressEvents(UUID)
}
