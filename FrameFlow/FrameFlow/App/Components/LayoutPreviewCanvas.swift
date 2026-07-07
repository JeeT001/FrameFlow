//
//  LayoutPreviewCanvas.swift
//  FrameFlow
//

import SwiftUI

struct LayoutPreviewCanvas: View {
    let format: RecordingFormat
    let preset: LayoutPreset
    let windowLabels: [String]
    let cameraEnabled: Bool
    var platformOverlay: PlatformPreviewOverlay = .none

    private var windowCount: Int {
        max(windowLabels.count, 1)
    }

    var body: some View {
        GeometryReader { geometry in
                let canvasSize = fittedCanvasSize(in: geometry.size)

                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppColors.surface)
                        .frame(width: canvasSize.width, height: canvasSize.height)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(AppColors.border)
                        }

                    layoutContent(in: canvasSize)
                        .padding(12)

                    if platformOverlay != .none {
                        PlatformSafeZoneOverlayView(
                            platform: platformOverlay,
                            canvasSize: canvasSize
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func fittedCanvasSize(in available: CGSize) -> CGSize {
        let ratio = format.aspectRatio
        let maxW = available.width
        let maxH = available.height

        var width = maxW
        var height = width / ratio
        if height > maxH {
            height = maxH
            width = height * ratio
        }
        return CGSize(width: width, height: height)
    }

    @ViewBuilder
    private func layoutContent(in size: CGSize) -> some View {
        switch preset {
        case .stacked:
            stackedPreview(size: size)
        case .sideBySide:
            sideBySidePreview(size: size)
        case .pipBottomRight:
            pipBottomRightPreview(size: size)
        case .pipFaceTop:
            pipFaceTopPreview(size: size)
        case .freeForm:
            freeFormPreview(size: size)
        }
    }

    private func stackedPreview(size: CGSize) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(windowLabels.prefix(4).enumerated()), id: \.offset) { _, label in
                windowPlaceholder(label: label, width: size.width - 24, height: (size.height - 32) / CGFloat(min(windowCount, 4)))
            }
        }
    }

    private func sideBySidePreview(size: CGSize) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(windowLabels.prefix(4).enumerated()), id: \.offset) { _, label in
                windowPlaceholder(
                    label: label,
                    width: (size.width - 32) / CGFloat(min(windowCount, 4)),
                    height: size.height - 24
                )
            }
        }
    }

    private func pipBottomRightPreview(size: CGSize) -> some View {
        ZStack(alignment: .bottomTrailing) {
            if let main = windowLabels.first {
                windowPlaceholder(label: main, width: size.width - 24, height: size.height - 24)
            }
            if windowLabels.count > 1 {
                windowPlaceholder(
                    label: windowLabels[1],
                    width: size.width * 0.28,
                    height: size.height * 0.22
                )
                .padding(16)
            }
            if cameraEnabled {
                cameraBadge
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
    }

    private func freeFormPreview(size: CGSize) -> some View {
        let count = max(min(windowLabels.count, 4), 1)
        let rects = WindowPlacementMath.freeFormDefaultPreviewRects(count: count, canvasSize: size)

        return ZStack {
            ForEach(Array(windowLabels.prefix(4).enumerated()), id: \.offset) { index, label in
                if index < rects.count {
                    let rect = rects[index]
                    windowPlaceholder(
                        label: label,
                        width: rect.width,
                        height: rect.height
                    )
                    .offset(
                        x: rect.midX - size.width / 2,
                        y: rect.midY - size.height / 2
                    )
                }
            }
        }
    }

    private func pipFaceTopPreview(size: CGSize) -> some View {
        ZStack(alignment: .top) {
            if windowLabels.count > 1 {
                windowPlaceholder(
                    label: windowLabels[1],
                    width: size.width - 24,
                    height: size.height * 0.55
                )
                .offset(y: size.height * 0.18)
            }
            if let main = windowLabels.first {
                windowPlaceholder(
                    label: main,
                    width: size.width * 0.4,
                    height: size.height * 0.28
                )
                .offset(y: 8)
            } else {
                windowPlaceholder(label: "Window 1", width: size.width * 0.4, height: size.height * 0.28)
                    .offset(y: 8)
            }
            if cameraEnabled {
                cameraBadge
                    .padding(.top, 52)
            }
        }
    }

    private func windowPlaceholder(label: String, width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(AppColors.primary.opacity(0.25))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(AppColors.primary.opacity(0.45))
                }
                .frame(width: max(width, 40), height: max(height, 28))

            Text(label.truncatedWindowTitle)
                .font(.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
        }
    }

    private var cameraBadge: some View {
        Label("Camera", systemImage: "video.fill")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial, in: Capsule())
    }
}
