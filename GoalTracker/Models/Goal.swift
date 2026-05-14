//
//  Goal.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation

final class Goal: Identifiable, Codable {
  var id: UUID = UUID()
  var name: String = ""
  var details: String?
  var createdAt: Date = Date()
  var dueDate: Date?
  var sortOrder: Int = 0
  var progress: GoalProgress = .outcomePending

  var isCompleted: Bool {
    progress.isCompleted
  }

  @discardableResult
  func complete() -> Bool {
    progress.complete()
  }

  @discardableResult
  func markPending() -> Bool {
    progress.reset()
  }

  @discardableResult
  func toggleCompletion() -> Bool {
    progress.toggleCompletion()
  }

  @discardableResult
  func incrementProgress() -> Bool {
    progress.increment()
  }

  @discardableResult
  func decrementProgress() -> Bool {
    progress.decrement()
  }

  init(
    id: UUID = UUID(),
    name: String,
    details: String?,
    dueDate: Date? = nil,
    createdAt: Date,
    sortOrder: Int = 0,
    progress: GoalProgress,
  ) {
    self.id = id
    self.name = name
    self.details = details
    self.dueDate = dueDate
    self.createdAt = createdAt
    self.sortOrder = sortOrder
    self.progress = progress
  }
}
