//
//  GoalProgressValueFormatter.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/8/26.
//

import Foundation

enum GoalProgressValueFormatter {
    
    static func string(
        from value: Double,
        unit: GoalProgressUnit?,
    ) -> String {
        guard let unit else {
            return value.formatted()
        }
        let valueText = formattedNumber(value)
        if let prefix = unit.prefix {
            return "\(prefix)\(valueText)"
        }
        if let suffix = unit.suffix {
            return "\(valueText) \(suffixText(suffix, value: value))"
        }
        return "\(valueText) \(unit.abbreviatedTitle)"
    }

    private static func formattedNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return Int(value).formatted()
        }
        return value.formatted()
    }

    private static func suffixText(_ suffix: String, value: Double) -> String {
        guard value == 1 else {
            return suffix
        }
        switch suffix {
        case "hours":
            return "hour"
        case "days":
            return "day"
        case "weeks":
            return "week"
        case "months":
            return "month"
        case "years":
            return "year"
        default:
            return suffix
        }
    }
}
