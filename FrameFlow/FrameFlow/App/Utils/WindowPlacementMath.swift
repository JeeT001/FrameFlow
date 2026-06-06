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
    static func cropFrameSize(placement: WindowPlacement, canvasSize: CGSize) -> CGSize {
        CGSize(
            width: canvasSize.width * placement.widthFraction,
            height: canvasSize.height * placement.heightFraction
        )
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
        canvasSize: CGSize,
        coordinateSpace: WindowPlacementCoordinateSpace
    ) -> CGRect {
        let size = cropFrameSize(placement: placement, canvasSize: canvasSize)
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
        canvasSize: CGSize,
        coordinateSpace: WindowPlacementCoordinateSpace
    ) -> CGRect {
        let size = cropFrameSize(placement: placement, canvasSize: canvasSize)
        let center = canvasCenter(placement: placement, canvasSize: canvasSize, coordinateSpace: coordinateSpace)
        return CGRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    static func heightFraction(
        forWidthFraction widthFraction: CGFloat,
        windowAspect: CGFloat,
        canvasSize: CGSize
    ) -> CGFloat {
        let canvasAspect = canvasSize.width / canvasSize.height
        let windowWidthOverHeight = 1.0 / windowAspect
        return widthFraction * canvasAspect / windowWidthOverHeight
    }

    static func syncPlacementToWindowAspect(
        _ placement: inout WindowPlacement,
        windowAspect: CGFloat,
        canvasSize: CGSize
    ) {
        placement.heightFraction = heightFraction(
            forWidthFraction: placement.widthFraction,
            windowAspect: windowAspect,
            canvasSize: canvasSize
        )
    }

    static func initialPlacementForWindow(
        windowAspect: CGFloat,
        canvasSize: CGSize,
        center: CGPoint,
        maxFraction: CGFloat = 0.88
    ) -> WindowPlacement {
        let canvasAspect = canvasSize.width / canvasSize.height
        let windowWidthOverHeight = 1.0 / windowAspect
        var widthFraction = maxFraction
        var heightFraction = widthFraction * canvasAspect / windowWidthOverHeight

        if heightFraction > maxFraction {
            heightFraction = maxFraction
            widthFraction = heightFraction * windowWidthOverHeight / canvasAspect
        }

        return WindowPlacement(
            center: center,
            widthFraction: widthFraction,
            heightFraction: heightFraction
        )
    }

    static func freeFormPosition(_ position: CGPoint) -> CGPoint {
        position
    }

    static func clampedPosition(
        _ position: CGPoint,
        widthFraction: CGFloat,
        heightFraction: CGFloat,
        canvasSize: CGSize
    ) -> CGPoint {
        let halfWidth = widthFraction / 2
        let halfHeight = heightFraction / 2
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
            return [CGRect(origin: .zero, size: canvasSize)]
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
                guard let placement = customPlacements[id], placement.hasValidCropFrame else { return nil }
                return canvasRectUnclamped(
                    for: placement,
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
                widthFraction: rect.width / canvasSize.width,
                heightFraction: rect.height / canvasSize.height
            )
        }
        return result
    }
}
