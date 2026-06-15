//
//  SettingsSliderRow.swift
//  FrameFlow
//

import SwiftUI

struct SettingsSliderRow: View {
    let title: String
    let valueLabel: String
    @Binding var sliderValue: Float
    let range: ClosedRange<Float>
    var step: Float?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Text(valueLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .monospacedDigit()
            }

            if let step {
                Slider(value: $sliderValue, in: range, step: step)
                    .tint(AppColors.primary)
            } else {
                Slider(value: $sliderValue, in: range)
                    .tint(AppColors.primary)
            }
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)
        }
        .toggleStyle(.switch)
        .tint(AppColors.primary)
    }
}
