//
//  GoalProgressUnit+Presets.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 6/10/26.
//

import Foundation

// MARK: - GoalProgressUnit+Presets

nonisolated extension GoalProgressUnit {
	static let dollars = requiredPreset(withId: "currency.usd")
	static let euros = requiredPreset(withId: "currency.eur")
	static let poundsSterling = requiredPreset(withId: "currency.gbp")
	static let minutes = requiredPreset(withId: "time.minutes")
	static let hours = requiredPreset(withId: "time.hours")
	static let days = requiredPreset(withId: "time.days")
	static let weeks = requiredPreset(withId: "time.weeks")
	static let months = requiredPreset(withId: "time.months")
	static let years = requiredPreset(withId: "time.years")
	static let pounds = requiredPreset(withId: "weight.pounds")
	static let kilograms = requiredPreset(withId: "weight.kilograms")
	static let ounces = requiredPreset(withId: "weight.ounces")
	static let grams = requiredPreset(withId: "weight.grams")
	static let miles = requiredPreset(withId: "distance.miles")
	static let kilometers = requiredPreset(withId: "distance.kilometers")
	static let steps = requiredPreset(withId: "distance.steps")
	static let meters = requiredPreset(withId: "distance.meters")
	static let feet = requiredPreset(withId: "distance.feet")
	static let floors = requiredPreset(withId: "distance.floors")
	static let repetitions = requiredPreset(withId: "quantity.repetitions")
	static let pages = requiredPreset(withId: "quantity.pages")
	static let books = requiredPreset(withId: "quantity.books")
	static let sessions = requiredPreset(withId: "quantity.sessions")
	static let tasks = requiredPreset(withId: "quantity.tasks")
	static let liters = requiredPreset(withId: "volume.liters")
	static let fluidOunces = requiredPreset(withId: "volume.ounces")
	static let calories = requiredPreset(withId: "energy.calories")

	static let presetSections: [PresetSection] = {
		let presetsByCategory = Dictionary(grouping: presets, by: \.category)
		return Category.allCases.compactMap { category in
			guard category != .custom,
				let units = presetsByCategory[category],
				!units.isEmpty
			else {
				return nil
			}
			return PresetSection(category: category, units: units)
		}
	}()

	static func preset(withId id: String) -> GoalProgressUnit? {
		presetsById[id]
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

	private static let presets = presetDefinitions.map(\.unit)

	private static let presetsById = Dictionary(
		uniqueKeysWithValues: presets.map { unit in
			(unit.id, unit)
		},
	)

	private static let presetDefinitions: [PresetDefinition] = [
		PresetDefinition(
			id: "currency.usd",
			category: .currency,
			title: .progressUnitCurrencyUsdTitle,
			abbreviatedTitle: .progressUnitCurrencyUsdAbbreviation,
			prefix: .progressUnitCurrencyUsdPrefix,
		),
		PresetDefinition(
			id: "currency.eur",
			category: .currency,
			title: .progressUnitCurrencyEurTitle,
			abbreviatedTitle: .progressUnitCurrencyEurAbbreviation,
			prefix: .progressUnitCurrencyEurPrefix,
		),
		PresetDefinition(
			id: "currency.gbp",
			category: .currency,
			title: .progressUnitCurrencyGbpTitle,
			abbreviatedTitle: .progressUnitCurrencyGbpAbbreviation,
			prefix: .progressUnitCurrencyGbpPrefix,
		),
		PresetDefinition(
			id: "time.minutes",
			category: .time,
			title: .progressUnitTimeMinutesTitle,
			abbreviatedTitle: .progressUnitTimeMinutesAbbreviation,
			suffix: .progressUnitTimeMinutesSuffix,
		),
		PresetDefinition(
			id: "time.hours",
			category: .time,
			title: .progressUnitTimeHoursTitle,
			abbreviatedTitle: .progressUnitTimeHoursAbbreviation,
			suffix: .progressUnitTimeHoursSuffix,
		),
		PresetDefinition(
			id: "time.days",
			category: .time,
			title: .progressUnitTimeDaysTitle,
			abbreviatedTitle: .progressUnitTimeDaysAbbreviation,
			suffix: .progressUnitTimeDaysSuffix,
		),
		PresetDefinition(
			id: "time.weeks",
			category: .time,
			title: .progressUnitTimeWeeksTitle,
			abbreviatedTitle: .progressUnitTimeWeeksAbbreviation,
			suffix: .progressUnitTimeWeeksSuffix,
		),
		PresetDefinition(
			id: "time.months",
			category: .time,
			title: .progressUnitTimeMonthsTitle,
			abbreviatedTitle: .progressUnitTimeMonthsAbbreviation,
			suffix: .progressUnitTimeMonthsSuffix,
		),
		PresetDefinition(
			id: "time.years",
			category: .time,
			title: .progressUnitTimeYearsTitle,
			abbreviatedTitle: .progressUnitTimeYearsAbbreviation,
			suffix: .progressUnitTimeYearsSuffix,
		),
		PresetDefinition(
			id: "weight.pounds",
			category: .weight,
			title: .progressUnitWeightPoundsTitle,
			abbreviatedTitle: .progressUnitWeightPoundsAbbreviation,
			suffix: .progressUnitWeightPoundsSuffix,
		),
		PresetDefinition(
			id: "weight.kilograms",
			category: .weight,
			title: .progressUnitWeightKilogramsTitle,
			abbreviatedTitle: .progressUnitWeightKilogramsAbbreviation,
			suffix: .progressUnitWeightKilogramsSuffix,
		),
		PresetDefinition(
			id: "weight.ounces",
			category: .weight,
			title: .progressUnitWeightOuncesTitle,
			abbreviatedTitle: .progressUnitWeightOuncesAbbreviation,
			suffix: .progressUnitWeightOuncesSuffix,
		),
		PresetDefinition(
			id: "weight.grams",
			category: .weight,
			title: .progressUnitWeightGramsTitle,
			abbreviatedTitle: .progressUnitWeightGramsAbbreviation,
			suffix: .progressUnitWeightGramsSuffix,
		),
		PresetDefinition(
			id: "distance.miles",
			category: .distance,
			title: .progressUnitDistanceMilesTitle,
			abbreviatedTitle: .progressUnitDistanceMilesAbbreviation,
			suffix: .progressUnitDistanceMilesSuffix,
		),
		PresetDefinition(
			id: "distance.kilometers",
			category: .distance,
			title: .progressUnitDistanceKilometersTitle,
			abbreviatedTitle: .progressUnitDistanceKilometersAbbreviation,
			suffix: .progressUnitDistanceKilometersSuffix,
		),
		PresetDefinition(
			id: "distance.steps",
			category: .distance,
			title: .progressUnitDistanceStepsTitle,
			abbreviatedTitle: .progressUnitDistanceStepsAbbreviation,
			suffix: .progressUnitDistanceStepsSuffix,
		),
		PresetDefinition(
			id: "distance.meters",
			category: .distance,
			title: .progressUnitDistanceMetersTitle,
			abbreviatedTitle: .progressUnitDistanceMetersAbbreviation,
			suffix: .progressUnitDistanceMetersSuffix,
		),
		PresetDefinition(
			id: "distance.feet",
			category: .distance,
			title: .progressUnitDistanceFeetTitle,
			abbreviatedTitle: .progressUnitDistanceFeetAbbreviation,
			suffix: .progressUnitDistanceFeetSuffix,
		),
		PresetDefinition(
			id: "distance.floors",
			category: .distance,
			title: .progressUnitDistanceFloorsTitle,
			abbreviatedTitle: .progressUnitDistanceFloorsAbbreviation,
			suffix: .progressUnitDistanceFloorsSuffix,
		),
		PresetDefinition(
			id: "quantity.repetitions",
			category: .quantity,
			title: .progressUnitQuantityRepetitionsTitle,
			abbreviatedTitle: .progressUnitQuantityRepetitionsAbbreviation,
			suffix: .progressUnitQuantityRepetitionsSuffix,
		),
		PresetDefinition(
			id: "quantity.pages",
			category: .quantity,
			title: .progressUnitQuantityPagesTitle,
			abbreviatedTitle: .progressUnitQuantityPagesAbbreviation,
			suffix: .progressUnitQuantityPagesSuffix,
		),
		PresetDefinition(
			id: "quantity.books",
			category: .quantity,
			title: .progressUnitQuantityBooksTitle,
			abbreviatedTitle: .progressUnitQuantityBooksAbbreviation,
			suffix: .progressUnitQuantityBooksSuffix,
		),
		PresetDefinition(
			id: "quantity.sessions",
			category: .quantity,
			title: .progressUnitQuantitySessionsTitle,
			abbreviatedTitle: .progressUnitQuantitySessionsAbbreviation,
			suffix: .progressUnitQuantitySessionsSuffix,
		),
		PresetDefinition(
			id: "quantity.tasks",
			category: .quantity,
			title: .progressUnitQuantityTasksTitle,
			abbreviatedTitle: .progressUnitQuantityTasksAbbreviation,
			suffix: .progressUnitQuantityTasksSuffix,
		),
		PresetDefinition(
			id: "volume.liters",
			category: .volume,
			title: .progressUnitVolumeLitersTitle,
			abbreviatedTitle: .progressUnitVolumeLitersAbbreviation,
			suffix: .progressUnitVolumeLitersSuffix,
		),
		PresetDefinition(
			id: "volume.ounces",
			category: .volume,
			title: .progressUnitVolumeOuncesTitle,
			abbreviatedTitle: .progressUnitVolumeOuncesAbbreviation,
			suffix: .progressUnitVolumeOuncesSuffix,
		),
		PresetDefinition(
			id: "energy.calories",
			category: .energy,
			title: .progressUnitEnergyCaloriesTitle,
			abbreviatedTitle: .progressUnitEnergyCaloriesAbbreviation,
			suffix: .progressUnitEnergyCaloriesSuffix,
		)
	]

	private static func requiredPreset(withId id: String) -> GoalProgressUnit {
		guard let preset = preset(withId: id) else {
			preconditionFailure("Missing goal progress unit preset with id: \(id)")
		}
		return preset
	}

	private struct PresetDefinition {
		let id: String
		let category: Category
		let title: LocalizedStringResource
		let abbreviatedTitle: LocalizedStringResource
		let prefix: LocalizedStringResource?
		let suffix: LocalizedStringResource?

		init(
			id: String,
			category: Category,
			title: LocalizedStringResource,
			abbreviatedTitle: LocalizedStringResource,
			prefix: LocalizedStringResource? = nil,
			suffix: LocalizedStringResource? = nil,
		) {
			self.id = id
			self.category = category
			self.title = title
			self.abbreviatedTitle = abbreviatedTitle
			self.prefix = prefix
			self.suffix = suffix
		}

		var unit: GoalProgressUnit {
			GoalProgressUnit(
				id: id,
				category: category,
				title: title,
				abbreviatedTitle: abbreviatedTitle,
				prefix: prefix,
				suffix: suffix,
			)
		}
	}
}
