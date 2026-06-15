//
//  WindowPickerCard.swift
//  FrameFlow
//

import SwiftUI

struct WindowPickerCard: View {
    let window: WindowItem
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    private static let previewAspectRatio: CGFloat = 16 / 10
    private static let iconCornerRadius: CGFloat = 8

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                topRow
                previewArea
                bottomLabels
            }
            .padding(14)
            .background(AppColors.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppColors.primary : AppColors.border.opacity(isHovered ? 0.9 : 0.6),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .shadow(color: .black.opacity(isHovered ? 0.08 : 0.03), radius: isHovered ? 8 : 3, y: 2)
            .scaleEffect(isHovered ? 1.01 : 1)
            .animation(.easeOut(duration: 0.12), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var topRow: some View {
        HStack(spacing: 10) {
            appIconView(size: 28)

            Spacer(minLength: 0)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .symbolRenderingMode(.palette)
                .foregroundStyle(
                    isSelected ? .white : AppColors.textSecondary.opacity(0.45),
                    isSelected ? AppColors.primary : AppColors.border
                )
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
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppColors.surface)

            VStack(spacing: 8) {
                appIconView(size: 44)
                Text("Preview unavailable")
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private var bottomLabels: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(window.appName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)

            Text(window.title)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
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
                .background(AppColors.surface, in: RoundedRectangle(cornerRadius: Self.iconCornerRadius))
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
