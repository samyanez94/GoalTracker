//
//  GoalSortDirection.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/16/26.
//

import Foundation

enum GoalSortDirection: String, CaseIterable, Identifiable {
    case ascending
    case descending

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .ascending:
            "Ascending"
        case .descending:
            "Descending"
        }
    }
}
