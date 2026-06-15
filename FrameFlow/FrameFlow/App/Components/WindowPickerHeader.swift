//
//  WindowPickerHeader.swift
//  FrameFlow
//

import SwiftUI

struct WindowPickerHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Select Windows")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Choose the windows you want to include in your recording.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
