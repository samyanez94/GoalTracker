//
//  AppStorageKey.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/14/26.
//

/// UserDefaults keys used with SwiftUI's `@AppStorage`.
///
/// Keeping these keys in one place makes preference storage easier to audit and
/// helps avoid accidental key drift between views.
enum AppStorageKey {
    static let goalSortMode = "goalSortMode"
    static let goalSortDirection = "goalSortDirection"
    static let isShowingCompletedGoals = "isShowingCompletedGoals"
    static let isPendingSectionExpanded = "isPendingSectionExpanded"
    static let isCompletedSectionExpanded = "isCompletedSectionExpanded"
}
