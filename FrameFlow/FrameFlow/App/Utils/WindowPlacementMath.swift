//
//  WindowPlacementMath.swift
//  FrameFlow
//

import CoreGraphics

enum WindowPlacementCoordinateSpace {
    /// Origin top-left, y increases downward (SwiftUI).
    case swiftUI
    /// Origin bottom-left, y increases upward (CIImage compositing).
    case coreImage
}

enum WindowPlacementMath {
    static func windowSize(
        placement: WindowPlacement,
        aspect: CGFloat,
        canvasSize: CGSize
    ) -> CGSize {
        let width = canvasSize.width * placement.widthFraction
        let height = width * aspect
        return CGSize(width: width, height: height)
    }

    static func canvasCenter(
        placement: WindowPlacement,
        canvasSize: CGSize,
        coordinateSpace: WindowPlacementCoordinateSpace
    ) -> CGPoint {
        let x = placement.center.x * canvasSize.width
        let yFromBottom = placement.center.y * canvasSize.height

        switch coordinateSpace {
        case .swiftUI:
            return CGPoint(x: x, y: canvasSize.height - yFromBottom)
        case .coreImage:
            return CGPoint(x: x, y: yFromBottom)
        }
    }

    static func canvasRect(
        for placement: WindowPlacement,
        aspect: CGFloat,
        canvasSize: CGSize,
        coordinateSpace: WindowPlacementCoordinateSpace
    ) -> CGRect {
        let size = windowSize(placement: placement, aspect: aspect, canvasSize: canvasSize)
        let center = canvasCenter(placement: placement, canvasSize: canvasSize, coordinateSpace: coordinateSpace)
        let rect = CGRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        return PiPLayoutMath.clampedRect(rect, in: canvasSize)
    }

    static func canvasRectUnclamped(
        for placement: WindowPlacement,
        aspect: CGFloat,
        canvasSize: CGSize,
        coordinateSpace: WindowPlacementCoordinateSpace
    ) -> CGRect {
        let size = windowSize(placement: placement, aspect: aspect, canvasSize: canvasSize)
        let center = canvasCenter(placement: placement, canvasSize: canvasSize, coordinateSpace: coordinateSpace)
        return CGRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    static func freeFormPosition(_ position: CGPoint) -> CGPoint {
        position
    }

    static func clampedPosition(
        _ position: CGPoint,
        widthFraction: CGFloat,
        aspect: CGFloat,
        canvasSize: CGSize
    ) -> CGPoint {
        let halfWidth = widthFraction / 2
        let halfHeight = (widthFraction * aspect) / 2
        return CGPoint(
            x: min(max(position.x, halfWidth), 1 - halfWidth),
            y: min(max(position.y, halfHeight), 1 - halfHeight)
        )
    }

    static func presetCanvasRects(
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

        case .freeForm:
            return defaultFreeFormRects(count: n, canvasSize: canvasSize)
        }
    }

    static func layoutRects(
        windowOrder: [CGWindowID],
        canvasSize: CGSize,
        preset: LayoutPreset,
        customPlacements: [CGWindowID: WindowPlacement]?,
        windowAspects: [CGWindowID: CGFloat]
    ) -> [CGRect] {
        if preset == .freeForm, let customPlacements {
            return windowOrder.compactMap { id in
                guard let placement = customPlacements[id] else { return nil }
                let aspect = windowAspects[id] ?? (9.0 / 16.0)
                return canvasRectUnclamped(
                    for: placement,
                    aspect: aspect,
                    canvasSize: canvasSize,
                    coordinateSpace: .coreImage
                )
            }
        }

        return presetCanvasRects(
            count: windowOrder.count,
            canvasSize: canvasSize,
            preset: preset
        )
    }

    static func placementsFromCanvasRects(
        windowOrder: [CGWindowID],
        rects: [CGRect],
        canvasSize: CGSize
    ) -> [CGWindowID: WindowPlacement] {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return [:] }

        var result: [CGWindowID: WindowPlacement] = [:]
        for (index, windowID) in windowOrder.enumerated() where index < rects.count {
            let rect = rects[index]
            result[windowID] = WindowPlacement(
                center: CGPoint(
                    x: rect.midX / canvasSize.width,
                    y: (canvasSize.height - rect.midY) / canvasSize.height
                ),
                widthFraction: rect.width / canvasSize.width
            )
        }
        return result
    }

    private static func defaultFreeFormRects(count: Int, canvasSize: CGSize) -> [CGRect] {
        let width = canvasSize.width
        let height = canvasSize.height
        let offsets: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0.35, 0.65, 0.55, 0.42),
            (0.65, 0.35, 0.55, 0.34),
            (0.28, 0.55, 0.4, 0.28),
            (0.72, 0.48, 0.36, 0.24),
        ]

        return (0..<min(count, 4)).map { index in
            let slot = offsets[index]
            let rectWidth = width * slot.2
            let rectHeight = height * slot.3
            let centerX = width * slot.0
            let centerYFromTop = height * (1 - slot.1)
            return CGRect(
                x: centerX - rectWidth / 2,
                y: centerYFromTop - rectHeight / 2,
                width: rectWidth,
                height: rectHeight
            )
        }
    }
}
