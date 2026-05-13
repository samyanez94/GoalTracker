//
//  GoalDueDateFormatter.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/5/26.
//

import Foundation

enum GoalDueDateFormatter {
  static func string(from date: Date) -> String {
    formatter.string(from: date)
  }

  private static let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    // Keep DateFormatter because FormatStyle does not offer the same localized relative date behavior.
    formatter.doesRelativeDateFormatting = true
    return formatter
  }()
}
