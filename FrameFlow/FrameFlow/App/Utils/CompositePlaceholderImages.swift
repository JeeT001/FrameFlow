//
//  CompositePlaceholderImages.swift
//  FrameFlow
//

import CoreImage
import Foundation

enum CompositePlaceholderImages {
    static func windowClosed(in rect: CGRect) -> CIImage {
        tiledPlaceholder(
            in: rect,
            fill: CIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1),
            accent: CIColor(red: 0.35, green: 0.38, blue: 0.45, alpha: 0.55)
        )
    }

    static func cameraUnavailable(in rect: CGRect) -> CIImage {
        tiledPlaceholder(
            in: rect,
            fill: CIColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1),
            accent: CIColor(red: 0.55, green: 0.58, blue: 0.65, alpha: 0.45)
        )
    }

    private static func tiledPlaceholder(
        in rect: CGRect,
        fill: CIColor,
        accent: CIColor
    ) -> CIImage {
        let base = CIImage(color: fill).cropped(to: rect)
        let stripeWidth = max(6, min(rect.width, rect.height) * 0.08)
        var stripes = CIImage(color: .clear).cropped(to: rect)

        var x = rect.minX - rect.height
        while x < rect.maxX + rect.height {
            let stripeRect = CGRect(
                x: x,
                y: rect.minY,
                width: stripeWidth,
                height: rect.height
            )
            let stripe = CIImage(color: accent).cropped(to: stripeRect)
            stripes = stripe.composited(over: stripes)
            x += stripeWidth * 2.4
        }

        return stripes.composited(over: base).cropped(to: rect)
    }
}
