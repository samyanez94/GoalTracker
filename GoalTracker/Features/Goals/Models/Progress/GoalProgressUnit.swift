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
		case quantity
		case volume
		case energy
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
			case .quantity:
				.progressUnitCategoryQuantity
			case .volume:
				.progressUnitCategoryVolume
			case .energy:
				.progressUnitCategoryEnergy
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
