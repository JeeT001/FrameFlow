//
//  WindowPickerCard.swift
//  FrameFlow
//

import SwiftUI

struct WindowPickerCard: View {
    let window: WindowItem
    let isSelected: Bool
    let onTap: () -> Void

    private static let previewAspectRatio: CGFloat = 16 / 10
    private static let iconCornerRadius: CGFloat = 10

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                header
                previewArea
                footer
            }
            .padding(12)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppColors.primary : AppColors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, AppColors.primary)
                        .padding(10)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        HStack(spacing: 10) {
            appIconView(size: 48)

            Text(window.appName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }

    private var previewArea: some View {
        Group {
            if ImageDisplayHelpers.hasDisplayableThumbnail(window.thumbnail),
               let image = ImageDisplayHelpers.thumbnailImage(from: window.thumbnail) {
                thumbnailPreview(image)
            } else {
                thumbnailFallback
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(Self.previewAspectRatio, contentMode: .fit)
        .frame(minHeight: 120)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func thumbnailPreview(_ image: Image) -> some View {
        GeometryReader { geometry in
            image
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
    }

    private var thumbnailFallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.background,
                            AppColors.surface,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                appIconView(size: 56)
                Text("Preview unavailable")
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private var footer: some View {
        Text(window.title)
            .font(.caption)
            .foregroundStyle(AppColors.textSecondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func appIconView(size: CGFloat) -> some View {
        if let icon = ImageDisplayHelpers.appIconImage(from: window.appIcon) {
            icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: Self.iconCornerRadius, style: .continuous))
        } else {
            Image(systemName: "app")
                .font(.system(size: size * 0.45))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: size, height: size)
                .background(AppColors.background, in: RoundedRectangle(cornerRadius: Self.iconCornerRadius))
        }
    }
}

#Preview {
    WindowPickerCard(
        window: WindowItem(
            id: 1,
            title: "GitHub — Pull Requests",
            appName: "Safari",
            bundleIdentifier: "com.apple.Safari",
            thumbnail: nil,
            appIcon: nil
        ),
        isSelected: true,
        onTap: {}
    )
    .frame(width: 240)
    .padding()
}
