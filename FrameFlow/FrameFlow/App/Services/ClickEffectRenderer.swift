//
//  ClickEffectRenderer.swift
//  FrameFlow
//

import CoreGraphics
import CoreImage
import Foundation

@MainActor
final class ClickEffectRenderer {
    private let transparent = CIColor(red: 0, green: 0, blue: 0, alpha: 0)

    func makeOverlay(
        clicks: [CursorClickEvent],
        cursorNormalizedPoint: CGPoint,
        showCursorHighlight: Bool,
        cursorColorName: String,
        canvasSize: CGSize,
        now: Date = Date()
    ) -> CIImage? {
        let canvasRect = CGRect(origin: .zero, size: canvasSize)
        var overlay: CIImage?

        if showCursorHighlight {
            let center = pointInCanvas(normalized: cursorNormalizedPoint, canvasSize: canvasSize)
            let cursorBase = cursorColor(for: cursorColorName)
            if let cursorHighlight = circle(
                center: center,
                radius: 16,
                color: CIColor(
                    red: cursorBase.red,
                    green: cursorBase.green,
                    blue: cursorBase.blue,
                    alpha: 0.55
                ),
                in: canvasRect
            ) {
                overlay = cursorHighlight
            }
        }

        for click in clicks {
            let elapsed = now.timeIntervalSince(click.timestamp)
            guard elapsed >= 0, elapsed <= 0.5 else { continue }
            let progress = min(max(elapsed / 0.5, 0), 1)

            let center = pointInCanvas(normalized: click.normalizedPoint, canvasSize: canvasSize)
            let startRadius: CGFloat = 12
            let endRadius: CGFloat = 48
            let radius = startRadius + (endRadius - startRadius) * progress
            let alpha = CGFloat(1 - progress) * 0.85

            let color = CIColor(red: 1, green: 1, blue: 1, alpha: alpha)
            if let ripple = ring(center: center, radius: radius, thickness: 4, color: color, in: canvasRect) {
                overlay = ripple.composited(over: overlay ?? CIImage.empty().cropped(to: canvasRect))
            }
        }

        return overlay
    }

    private func pointInCanvas(normalized: CGPoint, canvasSize: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(normalized.x, 0), 1) * canvasSize.width,
            y: min(max(normalized.y, 0), 1) * canvasSize.height
        )
    }

    private func ring(
        center: CGPoint,
        radius: CGFloat,
        thickness: CGFloat,
        color: CIColor,
        in canvasRect: CGRect
    ) -> CIImage? {
        guard let outer = CIFilter(
            name: "CIRadialGradient",
            parameters: [
                "inputCenter": CIVector(cgPoint: center),
                "inputRadius0": max(0, radius - thickness),
                "inputRadius1": radius,
                "inputColor0": color,
                "inputColor1": transparent,
            ]
        )?.outputImage?.cropped(to: canvasRect) else {
            return nil
        }
        return outer
    }

    private func circle(
        center: CGPoint,
        radius: CGFloat,
        color: CIColor,
        in canvasRect: CGRect
    ) -> CIImage? {
        guard let gradient = CIFilter(
            name: "CIRadialGradient",
            parameters: [
                "inputCenter": CIVector(cgPoint: center),
                "inputRadius0": 0,
                "inputRadius1": radius,
                "inputColor0": color,
                "inputColor1": transparent,
            ]
        )?.outputImage?.cropped(to: canvasRect) else {
            return nil
        }
        return gradient
    }

    private func cursorColor(for name: String) -> CIColor {
        switch name.lowercased() {
        case "blue":
            return CIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1)
        case "yellow":
            return CIColor(red: 1.0, green: 0.9, blue: 0.25, alpha: 1)
        case "white":
            fallthrough
        default:
            return CIColor(red: 1, green: 1, blue: 1, alpha: 1)
        }
    }
}
