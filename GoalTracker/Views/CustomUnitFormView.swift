//
//  CustomUnitFormView.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/9/26.
//

import SwiftUI

struct CustomUnitFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String

    @State private var abbreviation: String

    private let initialUnit: GoalProgressUnit?

    private let onSave: (GoalProgressUnit) -> Void

    init(
        initialUnit: GoalProgressUnit?,
        onSave: @escaping (GoalProgressUnit) -> Void,
    ) {
        self.initialUnit = initialUnit
        self.onSave = onSave
        _name = State(initialValue: initialUnit?.title ?? "")
        _abbreviation = State(initialValue: initialUnit?.abbreviatedTitle ?? "")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedAbbreviation: String {
        abbreviation.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSaveDisabled: Bool {
        trimmedName.isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                TextField("Abbreviation (optional)", text: $abbreviation)
            } footer: {
                Text("Values will display this text after the number.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Custom Unit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    save()
                } label: {
                    Image(systemName: "checkmark")
                }
                .tint(.blue)
                .buttonStyle(.glassProminent)
                .disabled(isSaveDisabled)
                .opacity(isSaveDisabled ? 0.5 : 1)
                .accessibilityLabel("Save")
            }
        }
    }

    private func save() {
        guard !isSaveDisabled else {
            return
        }
        let displayUnit = trimmedAbbreviation.isEmpty ? trimmedName : trimmedAbbreviation
        onSave(
            .custom(
                id: initialUnit?.id ?? "custom.\(UUID().uuidString)",
                title: trimmedName,
                abbreviatedTitle: displayUnit,
            ),
        )
        dismiss()
    }
}
