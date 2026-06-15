//
//  SettingsPageHeader.swift
//  FrameFlow
//

import SwiftUI

struct SettingsPageHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Customize \(AppBranding.name) to fit your workflow.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
