//
//  ProgressTextFieldRow.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/13/26.
//

import SwiftUI

struct ProgressTextFieldRow: View {
    let label: String
    let placeholder: String
    @Binding var value: Double?
    let focus: FocusState<Bool>.Binding

    var body: some View {
        HStack {
            Text(label)
            TextField(placeholder, value: $value, format: .number)
                .focused(focus)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
}
