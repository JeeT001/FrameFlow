//
//  CompositeEngine.swift
//  FrameFlow
//

import CoreGraphics
import CoreImage
import Foundation

@MainActor
final class CompositeEngine {
    static let shared = CompositeEngine()

    private let context = CIContext(options: [.useSoftwareRenderer: false])
    private(set) var latestCompositeImage: CGImage?
    private(set) var latestCompositeCIImage: CIImage?
    private var lastFocusedRect: CGRect?
    private var currentFocusedRect: CGRect?
    private var focusTransitionStart: Date?
    private var lastFocusedWindowID: CGWindowID?

    private init() {}

    @discardableResult
    func renderComposite(
        frames: [CGWindowID: CIImage],
        windowOrder: [CGWindowID],
        preset: LayoutPreset,
        format: RecordingFormat
    ) -> CGImage? {
        let canvasSize = outputSize(for: format)
        return renderComposite(
            frames: frames,
            windowOrder: windowOrder,
            preset: preset,
            canvasSize: canvasSize
        )
    }

    func renderComposite(
        frames: [CGWindowID: CIImage],
        windowOrder: [CGWindowID],
        preset: LayoutPreset,
        canvasSize: CGSize,
        zoomScale: CGFloat = 1.0,
        zoomFocalPointNormalized: CGPoint = CGPoint(x: 0.5, y: 0.5),
        clickOverlay: CIImage? = nil,
        activeWindowID: CGWindowID? = nil,
        autoFocusEnabled: Bool = false,
        cameraFrame: CIImage? = nil,
        pipConfig: PiPConfig? = nil,
        pipEnabled: Bool = false
    ) -> CGImage? {
        guard let ciImage = renderCompositeCIImage(
            frames: frames,
            windowOrder: windowOrder,
            preset: preset,
            canvasSize: canvasSize,
            zoomScale: zoomScale,
            zoomFocalPointNormalized: zoomFocalPointNormalized,
            clickOverlay: clickOverlay,
            activeWindowID: activeWindowID,
            autoFocusEnabled: autoFocusEnabled,
            cameraFrame: cameraFrame,
            pipConfig: pipConfig,
            pipEnabled: pipEnabled
        ) else {
            latestCompositeImage = nil
            latestCompositeCIImage = nil
            return nil
        }

        let canvasRect = CGRect(origin: .zero, size: canvasSize)
        guard let cgImage = context.createCGImage(ciImage, from: canvasRect) else {
            latestCompositeImage = nil
            return nil
        }

        latestCompositeImage = cgImage
        return cgImage
    }

    func outputSize(for format: RecordingFormat) -> CGSize {
        switch format {
        case .sixteenByNine:
            CGSize(width: 1280, height: 720)
        case .nineBySixteen:
            CGSize(width: 720, height: 1280)
        }
    }

    func renderCompositeCIImage(
        frames: [CGWindowID: CIImage],
        windowOrder: [CGWindowID],
        preset: LayoutPreset,
        format: RecordingFormat
    ) -> CIImage? {
        renderCompositeCIImage(
            frames: frames,
            windowOrder: windowOrder,
            preset: preset,
            canvasSize: outputSize(for: format)
        )
    }

    func renderCompositeCIImage(
        frames: [CGWindowID: CIImage],
        windowOrder: [CGWindowID],
        preset: LayoutPreset,
        canvasSize: CGSize,
        zoomScale: CGFloat = 1.0,
        zoomFocalPointNormalized: CGPoint = CGPoint(x: 0.5, y: 0.5),
        clickOverlay: CIImage? = nil,
        activeWindowID: CGWindowID? = nil,
        autoFocusEnabled: Bool = false,
        cameraFrame: CIImage? = nil,
        pipConfig: PiPConfig? = nil,
        pipEnabled: Bool = false
    ) -> CIImage? {
        let orderedImages = windowOrder.compactMap { frames[$0] }
        guard !orderedImages.isEmpty else {
            latestCompositeCIImage = nil
            return nil
        }

        let canvasRect = CGRect(origin: .zero, size: canvasSize)
        let placements = layoutRects(
            count: orderedImages.count,
            canvasSize: canvasSize,
            preset: preset
        )

        var composite = CIImage(color: CIColor(red: 0.05, green: 0.05, blue: 0.06))
            .cropped(to: canvasRect)

        for (image, targetRect) in zip(orderedImages, placements) {
            let placed = fit(image: image, in: targetRect)
            composite = placed.composited(over: composite)
        }

        composite = applyZoom(
            to: composite,
            scale: zoomScale,
            focalPointNormalized: zoomFocalPointNormalized,
            canvasRect: canvasRect
        )

        if let clickOverlay {
            composite = clickOverlay.composited(over: composite)
        }

        if autoFocusEnabled {
            if let focusOverlay = focusOverlayImage(
                activeWindowID: activeWindowID,
                windowOrder: windowOrder,
                placements: placements,
                canvasRect: canvasRect
            ) {
                composite = focusOverlay.composited(over: composite)
            }
        } else {
            clearFocusAnimationState()
        }

        if pipEnabled,
           let cameraFrame,
           let pipConfig {
            composite = applyPiPOverlay(
                to: composite,
                cameraFrame: cameraFrame,
                config: pipConfig,
                canvasRect: canvasRect
            )
        }

        latestCompositeCIImage = composite
        return composite
    }

    private func applyPiPOverlay(
        to base: CIImage,
        cameraFrame: CIImage,
        config: PiPConfig,
        canvasRect: CGRect
    ) -> CIImage {
        let pipRect = pipRect(for: config, canvasRect: canvasRect)
        guard pipRect.width > 4, pipRect.height > 4 else { return base }

        let pipImage = fit(image: cameraFrame, in: pipRect)
        let pipContent: CIImage
        switch config.shape {
        case .roundedRect:
            pipContent = pipImage
        case .circle:
            pipContent = circularCrop(image: pipImage, in: pipRect)
        }

        var result = pipContent.composited(over: base)
        if config.borderWidth > 0 {
            let borderColor = ciColor(for: config.borderColor)
            let border = strokeOverlay(
                for: pipRect,
                lineWidth: config.borderWidth,
                color: borderColor,
                canvasRect: canvasRect
            )
            result = border.composited(over: result)
        }
        return result
    }

    private func pipRect(for config: PiPConfig, canvasRect: CGRect) -> CGRect {
        let width = canvasRect.width * config.size
        let height = width * 9.0 / 16.0
        let center = CGPoint(
            x: canvasRect.minX + min(max(config.position.x, 0), 1) * canvasRect.width,
            y: canvasRect.minY + min(max(config.position.y, 0), 1) * canvasRect.height
        )
        return CGRect(
            x: center.x - width / 2,
            y: center.y - height / 2,
            width: width,
            height: height
        )
    }

    private func circularCrop(image: CIImage, in rect: CGRect) -> CIImage {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let mask = CIFilter(
            name: "CIRadialGradient",
            parameters: [
                "inputCenter": CIVector(cgPoint: center),
                "inputRadius0": max(0, radius - 1),
                "inputRadius1": radius,
                "inputColor0": CIColor(red: 1, green: 1, blue: 1, alpha: 1),
                "inputColor1": CIColor(red: 0, green: 0, blue: 0, alpha: 0),
            ]
        )?.outputImage?.cropped(to: rect) ?? CIImage(color: .white).cropped(to: rect)

        return CIFilter(
            name: "CIBlendWithMask",
            parameters: [
                kCIInputImageKey: image,
                kCIInputBackgroundImageKey: CIImage(color: .clear).cropped(to: rect),
                kCIInputMaskImageKey: mask,
            ]
        )?.outputImage?.cropped(to: rect) ?? image
    }

    private func ciColor(for style: PiPBorderStyle) -> CIColor {
        switch style {
        case .white:
            return CIColor(red: 1, green: 1, blue: 1, alpha: 0.95)
        case .blue:
            return CIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 0.95)
        case .black:
            return CIColor(red: 0, green: 0, blue: 0, alpha: 0.9)
        }
    }

    private func focusOverlayImage(
        activeWindowID: CGWindowID?,
        windowOrder: [CGWindowID],
        placements: [CGRect],
        canvasRect: CGRect
    ) -> CIImage? {
        let targetRect: CGRect?
        if let activeWindowID,
           let index = windowOrder.firstIndex(of: activeWindowID),
           index < placements.count {
            targetRect = placements[index]
        } else {
            targetRect = nil
        }

        updateFocusTransition(targetRect: targetRect, activeWindowID: activeWindowID)

        let alpha = focusTransitionAlpha()
        guard alpha > 0.01 else { return nil }

        let displayRect: CGRect?
        if let start = lastFocusedRect, let end = currentFocusedRect {
            let t = focusTransitionProgress()
            displayRect = interpolatedRect(from: start, to: end, t: t)
        } else {
            displayRect = currentFocusedRect ?? lastFocusedRect
        }

        guard let displayRect else { return nil }
        return strokeOverlay(
            for: displayRect.insetBy(dx: 2, dy: 2),
            lineWidth: 3,
            color: CIColor(red: 0.2, green: 0.5, blue: 1.0, alpha: alpha),
            canvasRect: canvasRect
        )
    }

    private func updateFocusTransition(targetRect: CGRect?, activeWindowID: CGWindowID?) {
        if activeWindowID != lastFocusedWindowID || targetRect != currentFocusedRect {
            lastFocusedRect = currentFocusedRect
            currentFocusedRect = targetRect
            focusTransitionStart = Date()
            lastFocusedWindowID = activeWindowID
        }
    }

    private func focusTransitionProgress() -> CGFloat {
        guard let focusTransitionStart else { return 1 }
        let elapsed = Date().timeIntervalSince(focusTransitionStart)
        return min(1, max(0, elapsed / 0.4))
    }

    private func focusTransitionAlpha() -> CGFloat {
        let t = focusTransitionProgress()
        switch (lastFocusedRect, currentFocusedRect) {
        case (nil, nil):
            return 0
        case (nil, .some):
            return t
        case (.some, nil):
            return 1 - t
        case (.some, .some):
            return 1
        }
    }

    private func interpolatedRect(from: CGRect, to: CGRect, t: CGFloat) -> CGRect {
        CGRect(
            x: from.origin.x + (to.origin.x - from.origin.x) * t,
            y: from.origin.y + (to.origin.y - from.origin.y) * t,
            width: from.size.width + (to.size.width - from.size.width) * t,
            height: from.size.height + (to.size.height - from.size.height) * t
        )
    }

    private func strokeOverlay(
        for rect: CGRect,
        lineWidth: CGFloat,
        color: CIColor,
        canvasRect: CGRect
    ) -> CIImage {
        let top = CIImage(color: color).cropped(to: CGRect(x: rect.minX, y: rect.maxY - lineWidth, width: rect.width, height: lineWidth))
        let bottom = CIImage(color: color).cropped(to: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: lineWidth))
        let left = CIImage(color: color).cropped(to: CGRect(x: rect.minX, y: rect.minY, width: lineWidth, height: rect.height))
        let right = CIImage(color: color).cropped(to: CGRect(x: rect.maxX - lineWidth, y: rect.minY, width: lineWidth, height: rect.height))

        return top
            .composited(over: bottom)
            .composited(over: left)
            .composited(over: right)
            .cropped(to: canvasRect)
    }

    private func clearFocusAnimationState() {
        lastFocusedRect = nil
        currentFocusedRect = nil
        focusTransitionStart = nil
        lastFocusedWindowID = nil
    }

    private func applyZoom(
        to image: CIImage,
        scale: CGFloat,
        focalPointNormalized: CGPoint,
        canvasRect: CGRect
    ) -> CIImage {
        let clampedScale = max(1, scale)
        guard clampedScale > 1.001 else { return image }

        let focalPoint = CGPoint(
            x: canvasRect.minX + min(max(focalPointNormalized.x, 0), 1) * canvasRect.width,
            y: canvasRect.minY + min(max(focalPointNormalized.y, 0), 1) * canvasRect.height
        )

        let zoomTransform = CGAffineTransform(translationX: focalPoint.x, y: focalPoint.y)
            .scaledBy(x: clampedScale, y: clampedScale)
            .translatedBy(x: -focalPoint.x, y: -focalPoint.y)

        return image
            .transformed(by: zoomTransform)
            .clampedToExtent()
            .cropped(to: canvasRect)
    }

    private func layoutRects(
        count: Int,
        canvasSize: CGSize,
        preset: LayoutPreset
    ) -> [CGRect] {
        let width = canvasSize.width
        let height = canvasSize.height
        let n = max(1, min(count, 4))

        switch preset {
        case .stacked:
            let sliceHeight = height / CGFloat(n)
            return (0..<n).map { index in
                let y = height - sliceHeight * CGFloat(index + 1)
                return CGRect(x: 0, y: y, width: width, height: sliceHeight)
            }

        case .sideBySide:
            let sliceWidth = width / CGFloat(n)
            return (0..<n).map { index in
                CGRect(x: sliceWidth * CGFloat(index), y: 0, width: sliceWidth, height: height)
            }

        case .pipBottomRight:
            guard n >= 2 else {
                return [CGRect(origin: .zero, size: canvasSize)]
            }
            let pipWidth = width * 0.28
            let pipHeight = height * 0.24
            return [
                CGRect(origin: .zero, size: canvasSize),
                CGRect(
                    x: width - pipWidth - 24,
                    y: 24,
                    width: pipWidth,
                    height: pipHeight
                ),
            ]

        case .pipFaceTop:
            guard n >= 2 else {
                return [CGRect(origin: .zero, size: canvasSize)]
            }
            let faceWidth = width * 0.36
            let faceHeight = height * 0.26
            return [
                CGRect(
                    x: (width - faceWidth) / 2,
                    y: height - faceHeight - 20,
                    width: faceWidth,
                    height: faceHeight
                ),
                CGRect(origin: .zero, size: canvasSize),
            ]
        }
    }

    private func fit(image: CIImage, in targetRect: CGRect) -> CIImage {
        let source = image.extent
        guard source.width > 0, source.height > 0 else { return image }

        let scale = min(targetRect.width / source.width, targetRect.height / source.height)
        let scaledWidth = source.width * scale
        let scaledHeight = source.height * scale
        let x = targetRect.minX + (targetRect.width - scaledWidth) / 2
        let y = targetRect.minY + (targetRect.height - scaledHeight) / 2

        return image
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .transformed(by: CGAffineTransform(translationX: x - source.minX * scale, y: y - source.minY * scale))
    }
}
