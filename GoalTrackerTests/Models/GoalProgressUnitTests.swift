//
//  GoalProgressUnitTests.swift
//  GoalTrackerTests
//
//  Created by Samuel Yanez on 5/12/26.
//

import Foundation
import Testing

@testable import GoalTracker

@MainActor
struct GoalProgressUnitTests {
  @Test
  func `Category titles are human readable`() {
    #expect(GoalProgressUnit.Category.currency.title == "Currency")
    #expect(GoalProgressUnit.Category.time.title == "Time")
    #expect(GoalProgressUnit.Category.weight.title == "Weight")
    #expect(GoalProgressUnit.Category.distance.title == "Distance")
    #expect(GoalProgressUnit.Category.custom.title == "Custom")
  }

  @Test
  func `Preset lookup returns the matching preset unit`() {
    let unit = GoalProgressUnit.preset(withID: "currency.usd")

    #expect(unit == .dollars)
  }

  @Test
  func `Preset lookup returns nil for an unknown id`() {
    let unit = GoalProgressUnit.preset(withID: "unknown.unit")

    #expect(unit == nil)
  }

  @Test
  func `Preset sections group units by category`() throws {
    let sections = GoalProgressUnit.presetSections

    #expect(sections.map(\.title) == ["Currency", "Time", "Weight", "Distance"])
    try #require(sections.count == 4)
    #expect(sections[0].units == [.dollars, .euros, .poundsSterling])
    #expect(sections[1].units == [.minutes, .hours, .days, .weeks, .months, .years])
    #expect(sections[2].units == [.pounds, .kilograms])
    #expect(sections[3].units == [.miles, .kilometers])
  }

  @Test
  func `Custom units use a custom category and suffix`() {
    let unit = GoalProgressUnit.custom(
      id: "custom.pages",
      title: "Pages",
      abbreviatedTitle: "pg",
    )

    #expect(unit.id == "custom.pages")
    #expect(unit.category == .custom)
    #expect(unit.title == "Pages")
    #expect(unit.abbreviatedTitle == "pg")
    #expect(unit.prefix == nil)
    #expect(unit.suffix == "pg")
  }

  @Test
  func `Decoding a preset id returns the current preset definition`() throws {
    let unit = try decodeUnit(
      """
      {
          "id": "currency.usd",
          "category": "custom",
          "title": "Outdated Dollars",
          "abbreviatedTitle": "USD",
          "prefix": null,
          "suffix": "dollars"
      }
      """,
    )

    #expect(unit == .dollars)
  }

  @Test
  func `Decoding a custom unit preserves stored values`() throws {
    let unit = try decodeUnit(
      """
      {
          "id": "custom.reps",
          "category": "custom",
          "title": "Repetitions",
          "abbreviatedTitle": "reps",
          "prefix": null,
          "suffix": "reps"
      }
      """,
    )

    #expect(unit.id == "custom.reps")
    #expect(unit.category == .custom)
    #expect(unit.title == "Repetitions")
    #expect(unit.abbreviatedTitle == "reps")
    #expect(unit.prefix == nil)
    #expect(unit.suffix == "reps")
  }

  @Test
  func `Decoding a custom unit without category defaults to custom`() throws {
    let unit = try decodeUnit(
      """
      {
          "id": "custom.books",
          "title": "Books",
          "abbreviatedTitle": "books",
          "prefix": null,
          "suffix": "books"
      }
      """,
    )

    #expect(unit.category == .custom)
  }

  private func decodeUnit(_ json: String) throws -> GoalProgressUnit {
    let data = json.data(using: .utf8)!
    return try JSONDecoder().decode(GoalProgressUnit.self, from: data)
  }
}
