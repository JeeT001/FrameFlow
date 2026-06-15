//
//  LayoutPickerNumberedSection.swift
//  FrameFlow
//

import SwiftUI

struct LayoutPickerNumberedSection<Content: View>: View {
    let number: Int
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("\(number).")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppColors.primary)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            content()
        }
    }
}
