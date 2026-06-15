//
//  LayoutFormatToggle.swift
//  FrameFlow
//

import SwiftUI

struct LayoutFormatToggle: View {
    @Binding var selection: RecordingFormat
    let isPro: Bool

    var body: some View {
        HStack(spacing: 12) {
            formatCard(
                format: .nineBySixteen,
                icon: "iphone",
                title: "9:16",
                subtitle: "Vertical (Portrait)"
            )
            formatCard(
                format: .sixteenByNine,
                icon: "rectangle",
                title: "16:9",
                subtitle: "Horizontal (Landscape)"
            )
        }
    }

    private func formatCard(
        format: RecordingFormat,
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        let isSelected = selection == format
        let showsProBadge = format == .nineBySixteen && !isPro

        return Button {
            selection = format
        } label: {
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    if showsProBadge {
                        Text("Pro")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppColors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.primary.opacity(0.12), in: Capsule())
                    }
                }
                .frame(height: showsProBadge ? nil : 0)

                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(AppColors.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppColors.primary : AppColors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
