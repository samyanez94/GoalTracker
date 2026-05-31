//
//  GoalProgressUnit.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/8/26.
//

import Foundation

/// Describes how measurable progress values should be displayed.
///
/// Preset units are resolved by `id` when decoded so saved goals automatically
/// use the latest built-in unit labels. Custom units keep their stored display
/// values.
nonisolated struct GoalProgressUnit: Codable, Hashable, Identifiable {
    /// The broad grouping used when presenting unit choices.
    nonisolated enum Category: String, Codable, CaseIterable, Identifiable {
        case currency
        case time
        case weight
        case distance
        case custom

        var id: Self {
            self
        }

        var title: String {
            switch self {
            case .currency:
                "Currency"
            case .time:
                "Time"
            case .weight:
                "Weight"
            case .distance:
                "Distance"
            case .custom:
                "Custom"
            }
        }
    }

    let id: String
    let category: Category
    let title: String
    let abbreviatedTitle: String
    let prefix: String?
    let suffix: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case category
        case title
        case abbreviatedTitle
        case prefix
        case suffix
    }

    init(
        id: String,
        category: Category,
        title: String,
        abbreviatedTitle: String,
        prefix: String?,
        suffix: String?,
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.abbreviatedTitle = abbreviatedTitle
        self.prefix = prefix
        self.suffix = suffix
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        if let preset = Self.preset(withID: id) {
            self = preset
            return
        }
        self.id = id
        category = try container.decodeIfPresent(Category.self, forKey: .category) ?? .custom
        title = try container.decode(String.self, forKey: .title)
        abbreviatedTitle = try container.decode(String.self, forKey: .abbreviatedTitle)
        prefix = try container.decodeIfPresent(String.self, forKey: .prefix)
        suffix = try container.decodeIfPresent(String.self, forKey: .suffix)
    }

    static let dollars = GoalProgressUnit(
        id: "currency.usd",
        category: .currency,
        title: "US Dollars",
        abbreviatedTitle: "$",
        prefix: "$",
        suffix: nil,
    )

    static let euros = GoalProgressUnit(
        id: "currency.eur",
        category: .currency,
        title: "Euros",
        abbreviatedTitle: "EUR",
        prefix: "€",
        suffix: nil,
    )

    static let poundsSterling = GoalProgressUnit(
        id: "currency.gbp",
        category: .currency,
        title: "British Pound",
        abbreviatedTitle: "GBP",
        prefix: "£",
        suffix: nil,
    )

    static let minutes = GoalProgressUnit(
        id: "time.minutes",
        category: .time,
        title: "Minutes",
        abbreviatedTitle: "min",
        prefix: nil,
        suffix: "min",
    )

    static let hours = GoalProgressUnit(
        id: "time.hours",
        category: .time,
        title: "Hours",
        abbreviatedTitle: "hours",
        prefix: nil,
        suffix: "hours",
    )

    static let days = GoalProgressUnit(
        id: "time.days",
        category: .time,
        title: "Days",
        abbreviatedTitle: "days",
        prefix: nil,
        suffix: "days",
    )

    static let weeks = GoalProgressUnit(
        id: "time.weeks",
        category: .time,
        title: "Weeks",
        abbreviatedTitle: "weeks",
        prefix: nil,
        suffix: "weeks",
    )

    static let months = GoalProgressUnit(
        id: "time.months",
        category: .time,
        title: "Months",
        abbreviatedTitle: "months",
        prefix: nil,
        suffix: "months",
    )

    static let years = GoalProgressUnit(
        id: "time.years",
        category: .time,
        title: "Years",
        abbreviatedTitle: "years",
        prefix: nil,
        suffix: "years",
    )

    static let pounds = GoalProgressUnit(
        id: "weight.pounds",
        category: .weight,
        title: "Pounds",
        abbreviatedTitle: "lb",
        prefix: nil,
        suffix: "lb",
    )

    static let kilograms = GoalProgressUnit(
        id: "weight.kilograms",
        category: .weight,
        title: "Kilograms",
        abbreviatedTitle: "kg",
        prefix: nil,
        suffix: "kg",
    )

    static let miles = GoalProgressUnit(
        id: "distance.miles",
        category: .distance,
        title: "Miles",
        abbreviatedTitle: "mi",
        prefix: nil,
        suffix: "mi",
    )

    static let kilometers = GoalProgressUnit(
        id: "distance.kilometers",
        category: .distance,
        title: "Kilometers",
        abbreviatedTitle: "km",
        prefix: nil,
        suffix: "km",
    )

    static let presetSections: [PresetSection] = [
        PresetSection(
            title: Category.currency.title,
            units: [.dollars, .euros, .poundsSterling],
        ),
        PresetSection(
            title: Category.time.title,
            units: [.minutes, .hours, .days, .weeks, .months, .years],
        ),
        PresetSection(
            title: Category.weight.title,
            units: [.pounds, .kilograms],
        ),
        PresetSection(
            title: Category.distance.title,
            units: [.miles, .kilometers],
        ),
    ]

    static func preset(withID id: String) -> GoalProgressUnit? {
        presetSections
            .flatMap(\.units)
            .first { $0.id == id }
    }

    static func custom(
        id: String = "custom.\(UUID().uuidString)",
        title: String,
        abbreviatedTitle: String,
    ) -> GoalProgressUnit {
        GoalProgressUnit(
            id: id,
            category: .custom,
            title: title,
            abbreviatedTitle: abbreviatedTitle,
            prefix: nil,
            suffix: abbreviatedTitle,
        )
    }

    struct PresetSection: Identifiable {
        let title: String
        let units: [GoalProgressUnit]

        var id: String {
            title
        }
    }
}
