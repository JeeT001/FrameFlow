//
//  SettingsPickerRow.swift
//  FrameFlow
//

import SwiftUI

struct SettingsPickerRow<SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)

            Spacer(minLength: 12)

            Picker(title, selection: $selection) {
                content()
            }
            .labelsHidden()
            .frame(maxWidth: 220)
        }
    }
}

struct SettingsLabeledValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

struct SettingsButtonRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Button(title, action: action)
                .buttonStyle(.bordered)
        }
    }
}
