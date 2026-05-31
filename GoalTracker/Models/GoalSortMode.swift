//
//  GoalSortMode.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/8/26.
//

import Foundation

enum GoalSortMode: String, CaseIterable, Identifiable {
    case dueDate
    case creationDate
    case name

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .dueDate:
            "Due Date"
        case .creationDate:
            "Date Created"
        case .name:
            "Name"
        }
    }
}
