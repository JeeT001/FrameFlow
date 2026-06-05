//
//  PiPLayoutMath.swift
//  FrameFlow
//

import CoreGraphics

enum PiPCoordinateSpace {
    /// Origin top-left, y increases downward (SwiftUI).
    case swiftUI
    /// Origin bottom-left, y increases upward (CIImage compositing).
    case coreImage
}

enum PiPLayoutMath {
    /// `config.position`: x 0=left, 1=right; y 0=bottom, 1=top (matches PiPController presets).
    static func pipSize(config: PiPConfig, canvasSize: CGSize) -> CGSize {
        let width = canvasSize.width * config.size
        let height = width * 9.0 / 16.0
        return CGSize(width: width, height: height)
    }

    static func pipCenter(
        config: PiPConfig,
        canvasSize: CGSize,
        coordinateSpace: PiPCoordinateSpace
    ) -> CGPoint {
        // config.position.y: 0 = bottom, 1 = top (normalized from canvas bottom).
        let x = config.position.x * canvasSize.width
        let yFromBottom = config.position.y * canvasSize.height

        switch coordinateSpace {
        case .swiftUI:
            // swiftUI center.y = canvasHeight - (position.y * canvasHeight)
            return CGPoint(x: x, y: canvasSize.height - yFromBottom)
        case .coreImage:
            // coreImage center.y = position.y * canvasHeight (origin bottom-left)
            return CGPoint(x: x, y: yFromBottom)
        }
    }

    static func pipRect(
        config: PiPConfig,
        canvasSize: CGSize,
        coordinateSpace: PiPCoordinateSpace
    ) -> CGRect {
        let size = pipSize(config: config, canvasSize: canvasSize)
        let center = pipCenter(config: config, canvasSize: canvasSize, coordinateSpace: coordinateSpace)
        let rect = CGRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        return clampedRect(rect, in: canvasSize)
    }

    static func pipRectUnclamped(
        config: PiPConfig,
        canvasSize: CGSize,
        coordinateSpace: PiPCoordinateSpace
    ) -> CGRect {
        let size = pipSize(config: config, canvasSize: canvasSize)
        let center = pipCenter(config: config, canvasSize: canvasSize, coordinateSpace: coordinateSpace)
        return CGRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    static func clampedPosition(
        _ position: CGPoint,
        size: CGFloat,
        canvasSize: CGSize
    ) -> CGPoint {
        if size > 1.0 {
            return position
        }
        let halfWidth = size / 2
        let halfHeight = (size * 9.0 / 16.0) / 2
        return CGPoint(
            x: min(max(position.x, halfWidth), 1 - halfWidth),
            y: min(max(position.y, halfHeight), 1 - halfHeight)
        )
    }

    static func clampedRect(_ rect: CGRect, in canvasSize: CGSize) -> CGRect {
        let bounds = CGRect(origin: .zero, size: canvasSize)
        if rect.width > bounds.width || rect.height > bounds.height {
            return rect
        }

        var clamped = rect
        if clamped.minX < bounds.minX {
            clamped.origin.x = bounds.minX
        }
        if clamped.minY < bounds.minY {
            clamped.origin.y = bounds.minY
        }
        if clamped.maxX > bounds.maxX {
            clamped.origin.x = bounds.maxX - clamped.width
        }
        if clamped.maxY > bounds.maxY {
            clamped.origin.y = bounds.maxY - clamped.height
        }

        clamped.origin.x = max(bounds.minX, clamped.origin.x)
        clamped.origin.y = max(bounds.minY, clamped.origin.y)
        return clamped
    }
}
