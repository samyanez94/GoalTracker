//
//  GoalProgressUnit.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/8/26.
//

import Foundation

// MARK: - GoalProgressUnit

/// Describes the unit shown next to a measurable goal's progress.
///
/// A unit provides the labels and optional prefix or suffix used when presenting values, such as
/// dollars, minutes, pounds, or a custom unit created by the user.
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

		var title: LocalizedStringResource {
			switch self {
			case .currency:
				.progressUnitCategoryCurrency
			case .time:
				.progressUnitCategoryTime
			case .weight:
				.progressUnitCategoryWeight
			case .distance:
				.progressUnitCategoryDistance
			case .custom:
				.commonCustom
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

	init(
		id: String,
		category: Category,
		title: LocalizedStringResource,
		abbreviatedTitle: LocalizedStringResource,
		prefix: LocalizedStringResource? = nil,
		suffix: LocalizedStringResource? = nil,
	) {
		self.init(
			id: id,
			category: category,
			title: String(localized: title),
			abbreviatedTitle: String(localized: abbreviatedTitle),
			prefix: prefix.map { String(localized: $0) },
			suffix: suffix.map { String(localized: $0) },
		)
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let id = try container.decode(String.self, forKey: .id)
		if let preset = Self.preset(withId: id) {
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
}

// MARK: - GoalProgressUnit+Presets

nonisolated extension GoalProgressUnit {
	static let dollars = GoalProgressUnit(
		id: "currency.usd",
		category: .currency,
		title: .progressUnitCurrencyUsdTitle,
		abbreviatedTitle: .progressUnitCurrencyUsdAbbreviation,
		prefix: .progressUnitCurrencyUsdPrefix,
	)

	static let euros = GoalProgressUnit(
		id: "currency.eur",
		category: .currency,
		title: .progressUnitCurrencyEurTitle,
		abbreviatedTitle: .progressUnitCurrencyEurAbbreviation,
		prefix: .progressUnitCurrencyEurPrefix,
	)

	static let poundsSterling = GoalProgressUnit(
		id: "currency.gbp",
		category: .currency,
		title: .progressUnitCurrencyGbpTitle,
		abbreviatedTitle: .progressUnitCurrencyGbpAbbreviation,
		prefix: .progressUnitCurrencyGbpPrefix,
	)

	static let minutes = GoalProgressUnit(
		id: "time.minutes",
		category: .time,
		title: .progressUnitTimeMinutesTitle,
		abbreviatedTitle: .progressUnitTimeMinutesAbbreviation,
		suffix: .progressUnitTimeMinutesSuffix,
	)

	static let hours = GoalProgressUnit(
		id: "time.hours",
		category: .time,
		title: .progressUnitTimeHoursTitle,
		abbreviatedTitle: .progressUnitTimeHoursAbbreviation,
		suffix: .progressUnitTimeHoursSuffix,
	)

	static let days = GoalProgressUnit(
		id: "time.days",
		category: .time,
		title: .progressUnitTimeDaysTitle,
		abbreviatedTitle: .progressUnitTimeDaysAbbreviation,
		suffix: .progressUnitTimeDaysSuffix,
	)

	static let weeks = GoalProgressUnit(
		id: "time.weeks",
		category: .time,
		title: .progressUnitTimeWeeksTitle,
		abbreviatedTitle: .progressUnitTimeWeeksAbbreviation,
		suffix: .progressUnitTimeWeeksSuffix,
	)

	static let months = GoalProgressUnit(
		id: "time.months",
		category: .time,
		title: .progressUnitTimeMonthsTitle,
		abbreviatedTitle: .progressUnitTimeMonthsAbbreviation,
		suffix: .progressUnitTimeMonthsSuffix,
	)

	static let years = GoalProgressUnit(
		id: "time.years",
		category: .time,
		title: .progressUnitTimeYearsTitle,
		abbreviatedTitle: .progressUnitTimeYearsAbbreviation,
		suffix: .progressUnitTimeYearsSuffix,
	)

	static let pounds = GoalProgressUnit(
		id: "weight.pounds",
		category: .weight,
		title: .progressUnitWeightPoundsTitle,
		abbreviatedTitle: .progressUnitWeightPoundsAbbreviation,
		suffix: .progressUnitWeightPoundsSuffix,
	)

	static let kilograms = GoalProgressUnit(
		id: "weight.kilograms",
		category: .weight,
		title: .progressUnitWeightKilogramsTitle,
		abbreviatedTitle: .progressUnitWeightKilogramsAbbreviation,
		suffix: .progressUnitWeightKilogramsSuffix,
	)

	static let miles = GoalProgressUnit(
		id: "distance.miles",
		category: .distance,
		title: .progressUnitDistanceMilesTitle,
		abbreviatedTitle: .progressUnitDistanceMilesAbbreviation,
		suffix: .progressUnitDistanceMilesSuffix,
	)

	static let kilometers = GoalProgressUnit(
		id: "distance.kilometers",
		category: .distance,
		title: .progressUnitDistanceKilometersTitle,
		abbreviatedTitle: .progressUnitDistanceKilometersAbbreviation,
		suffix: .progressUnitDistanceKilometersSuffix,
	)

	static let presetSections: [PresetSection] = [
		PresetSection(
			category: .currency,
			units: [.dollars, .euros, .poundsSterling],
		),
		PresetSection(
			category: .time,
			units: [.minutes, .hours, .days, .weeks, .months, .years],
		),
		PresetSection(
			category: .weight,
			units: [.pounds, .kilograms],
		),
		PresetSection(
			category: .distance,
			units: [.miles, .kilometers],
		)
	]

	static func preset(withId id: String) -> GoalProgressUnit? {
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
		let category: Category
		let units: [GoalProgressUnit]

		var id: Category {
			category
		}

		var title: LocalizedStringResource {
			category.title
		}
	}
}

// MARK: - GoalProgressUnitStorage

/// Stores an optional progress unit without making the whole unit value optional.
///
/// SwiftData can struggle when an optional nested Codable value is nil. This storage type keeps the persisted composite present and treats a missing `id` as no selected unit.
///
/// See FB21496971: https://openradar.appspot.com/FB21496971
nonisolated struct GoalProgressUnitStorage: Codable, Equatable {
	private let id: String?
	private let category: String?
	private let title: String?
	private let abbreviatedTitle: String?
	private let prefix: String?
	private let suffix: String?

	init() {
		id = nil
		category = nil
		title = nil
		abbreviatedTitle = nil
		prefix = nil
		suffix = nil
	}

	init(_ unit: GoalProgressUnit?) {
		id = unit?.id
		category = unit?.category.rawValue
		title = unit?.title
		abbreviatedTitle = unit?.abbreviatedTitle
		prefix = unit?.prefix
		suffix = unit?.suffix
	}

	func resolvedUnit() -> GoalProgressUnit? {
		guard let id else {
			return nil
		}
		if let preset = GoalProgressUnit.preset(withId: id) {
			return preset
		}
		let fallbackTitle = title ?? abbreviatedTitle ?? id
		return GoalProgressUnit(
			id: id,
			category: category.flatMap(GoalProgressUnit.Category.init(rawValue:)) ?? .custom,
			title: fallbackTitle,
			abbreviatedTitle: abbreviatedTitle ?? fallbackTitle,
			prefix: prefix,
			suffix: suffix,
		)
	}
}
