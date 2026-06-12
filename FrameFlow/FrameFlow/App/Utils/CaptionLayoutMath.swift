//
//  CaptionLayoutMath.swift
//  FrameFlow
//

import CoreGraphics
import Foundation

/// Shared caption box layout for SwiftUI preview and Core Animation export burn-in.
enum CaptionLayoutMath {
    static let referenceHeight: CGFloat = 1080
    static let maxWidthFraction: CGFloat = 0.88
    static let textHeightMultiplier: CGFloat = 1.35
    static let backgroundPaddingReference: CGFloat = 14

    static func scale(for containerHeight: CGFloat) -> CGFloat {
        containerHeight / referenceHeight
    }

    static func scaledFontSize(style: CaptionStyleConfig, containerHeight: CGFloat) -> CGFloat {
        style.fontSize * scale(for: containerHeight)
    }

    static func estimatedBoxHeight(style: CaptionStyleConfig, containerHeight: CGFloat) -> CGFloat {
        let layoutScale = scale(for: containerHeight)
        let fontSize = style.fontSize * layoutScale
        let textHeight = fontSize * textHeightMultiplier
        let padding: CGFloat = style.showsBackground ? backgroundPaddingReference * layoutScale : 0
        return textHeight + padding * 2
    }

    static func captionFrame(style: CaptionStyleConfig, containerSize: CGSize) -> CGRect {
        let maxWidth = containerSize.width * maxWidthFraction
        let boxHeight = estimatedBoxHeight(style: style, containerHeight: containerSize.height)
        let originY = style.captionOriginY(renderHeight: containerSize.height, boxHeight: boxHeight)
        return CGRect(
            x: (containerSize.width - maxWidth) / 2,
            y: originY,
            width: maxWidth,
            height: boxHeight
        )
    }

    static func cornerRadius(style: CaptionStyleConfig, containerHeight: CGFloat) -> CGFloat {
        8 * scale(for: containerHeight)
    }

    static func backgroundPadding(containerHeight: CGFloat) -> CGFloat {
        backgroundPaddingReference * scale(for: containerHeight)
    }
}
