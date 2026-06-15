//
//  SettingsPermissionRow.swift
//  FrameFlow
//

import SwiftUI

struct SettingsPermissionRow: View {
    let icon: String
    let title: String
    let status: String
    let onCheckStatus: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppColors.textPrimary)

                    HStack(spacing: 12) {
                        Button("Check Status", action: onCheckStatus)
                        Button("Open System Settings", action: onOpenSettings)
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }

                Spacer(minLength: 8)

                statusBadge

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        Text(status)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(badgeForeground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeBackground, in: Capsule())
    }

    private var isGranted: Bool {
        status.lowercased() == "granted"
    }

    private var badgeForeground: Color {
        isGranted ? AppColors.successGreen : AppColors.textSecondary
    }

    private var badgeBackground: Color {
        isGranted ? AppColors.successGreen.opacity(0.15) : AppColors.textSecondary.opacity(0.12)
    }
}
