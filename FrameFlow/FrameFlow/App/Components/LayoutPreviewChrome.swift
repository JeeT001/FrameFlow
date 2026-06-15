//
//  LayoutPreviewChrome.swift
//  FrameFlow
//

import SwiftUI

struct LayoutPreviewChrome<Content: View>: View {
    let isLive: Bool
    let format: RecordingFormat
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text("Preview")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                if isLive {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppColors.successGreen)
                            .frame(width: 8, height: 8)
                        Text("Live preview")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.successGreen)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColors.successGreen.opacity(0.12), in: Capsule())
                }

                Spacer()

                formatLabel
            }

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.surface)

                content()
                    .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var formatLabel: some View {
        HStack(spacing: 8) {
            formatChip(
                title: "Phone (9:16)",
                isActive: format == .nineBySixteen
            )
            formatChip(
                title: "Landscape (16:9)",
                isActive: format == .sixteenByNine
            )
        }
    }

    private func formatChip(title: String, isActive: Bool) -> some View {
        Text(title)
            .font(.caption2.weight(.medium))
            .foregroundStyle(isActive ? AppColors.primary : AppColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                isActive ? AppColors.primary.opacity(0.1) : AppColors.background,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .strokeBorder(isActive ? AppColors.primary.opacity(0.35) : AppColors.border)
            }
    }
}
