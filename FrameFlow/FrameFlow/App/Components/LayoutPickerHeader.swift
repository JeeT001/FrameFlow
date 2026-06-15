//
//  LayoutPickerHeader.swift
//  FrameFlow
//

import SwiftUI

struct LayoutPickerHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Layout")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Configure how your recording will look.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
