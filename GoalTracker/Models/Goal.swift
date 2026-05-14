//
//  Goal.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/2/26.
//

import Foundation

struct Goal: Identifiable, Codable {
  let id: UUID
  var name: String
  var description: String?
  let createdAt: Date
  var dueDate: Date?
  var sortOrder: Int
  var progress: GoalProgress

  var isCompleted: Bool {
    progress.isCompleted
  }

  @discardableResult
  mutating func complete() -> Bool {
    progress.complete()
  }

  @discardableResult
  mutating func markPending() -> Bool {
    progress.reset()
  }

  @discardableResult
  mutating func toggleCompletion() -> Bool {
    progress.toggleCompletion()
  }

  @discardableResult
  mutating func incrementProgress() -> Bool {
    progress.increment()
  }

  @discardableResult
  mutating func decrementProgress() -> Bool {
    progress.decrement()
  }

  init(
    id: UUID = UUID(),
    name: String,
    description: String?,
    dueDate: Date? = nil,
    createdAt: Date,
    sortOrder: Int = 0,
    progress: GoalProgress,
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.dueDate = dueDate
    self.createdAt = createdAt
    self.sortOrder = sortOrder
    self.progress = progress
  }
}
