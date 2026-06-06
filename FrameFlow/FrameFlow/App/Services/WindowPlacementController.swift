//
//  WindowPlacementController.swift
//  FrameFlow
//

import CoreGraphics
import CoreImage
import Foundation
import ScreenCaptureKit

@MainActor
@Observable
final class WindowPlacementController {
    var placements: [CGWindowID: WindowPlacement] = [:]
    var allowsOverflow: Bool = true

    private var windowAspects: [CGWindowID: CGFloat] = [:]

    func needsReseed(for windowIDs: [CGWindowID]) -> Bool {
        guard !windowIDs.isEmpty else { return false }
        for windowID in windowIDs {
            guard let placement = placements[windowID], placement.hasValidCropFrame else {
                return true
            }
        }
        return false
    }

    func seedFromPreset(
        _ preset: LayoutPreset,
        windowIDs: [CGWindowID],
        canvasSize: CGSize
    ) {
        updateAspects(for: windowIDs)

        let seedPreset: LayoutPreset = preset == .freeForm ? .stacked : preset
        let rects = WindowPlacementMath.presetCanvasRects(
            count: windowIDs.count,
            canvasSize: canvasSize,
            preset: seedPreset
        )
        placements = WindowPlacementMath.placementsFromCanvasRects(
            windowOrder: windowIDs,
            rects: rects,
            canvasSize: canvasSize
        )
    }

    func seedFreeFormDefault(
        windowIDs: [CGWindowID],
        canvasSize: CGSize
    ) {
        updateAspects(for: windowIDs)

        let defaultCenters: [CGPoint] = [
            CGPoint(x: 0.5, y: 0.5),
            CGPoint(x: 0.35, y: 0.65),
            CGPoint(x: 0.65, y: 0.35),
            CGPoint(x: 0.28, y: 0.55),
        ]

        var result: [CGWindowID: WindowPlacement] = [:]
        for (index, windowID) in windowIDs.enumerated() {
            let aspect = aspectRatio(for: windowID)
            let center = defaultCenters[min(index, defaultCenters.count - 1)]
            result[windowID] = WindowPlacementMath.initialPlacementForWindow(
                windowAspect: aspect,
                canvasSize: canvasSize,
                center: center
            )
        }
        placements = result
    }

    func updatePosition(
        windowID: CGWindowID,
        center: CGPoint,
        canvasSize: CGSize
    ) {
        guard var placement = placements[windowID] else { return }
        if allowsOverflow {
            placement.center = WindowPlacementMath.freeFormPosition(center)
        } else {
            placement.center = WindowPlacementMath.clampedPosition(
                center,
                widthFraction: placement.widthFraction,
                heightFraction: placement.heightFraction,
                canvasSize: canvasSize
            )
        }
        placements[windowID] = placement
    }

    func updateSize(
        windowID: CGWindowID,
        widthFraction: CGFloat,
        canvasSize: CGSize
    ) {
        guard var placement = placements[windowID] else { return }
        let minSize: CGFloat = 0.12
        let maxWidth: CGFloat = allowsOverflow ? 3.0 : 0.95
        let maxHeight: CGFloat = allowsOverflow ? 3.0 : 0.95

        placement.widthFraction = min(max(widthFraction, minSize), maxWidth)
        let aspect = aspectRatio(for: windowID)
        WindowPlacementMath.syncPlacementToWindowAspect(
            &placement,
            windowAspect: aspect,
            canvasSize: canvasSize
        )
        placement.heightFraction = min(max(placement.heightFraction, minSize), maxHeight)

        if allowsOverflow {
            placement.center = WindowPlacementMath.freeFormPosition(placement.center)
        } else {
            placement.center = WindowPlacementMath.clampedPosition(
                placement.center,
                widthFraction: placement.widthFraction,
                heightFraction: placement.heightFraction,
                canvasSize: canvasSize
            )
        }
        placements[windowID] = placement
    }

    func updateAspectFromCapture(windowID: CGWindowID, image: CIImage) {
        let extent = image.extent
        guard extent.width > 0 else { return }
        windowAspects[windowID] = extent.height / extent.width
    }

    func aspectRatio(for windowID: CGWindowID) -> CGFloat {
        if let aspect = windowAspects[windowID] {
            return aspect
        }
        if let window = WindowCaptureService.shared.scWindow(for: windowID),
           window.frame.width > 0 {
            return window.frame.height / window.frame.width
        }
        return 9.0 / 16.0
    }

    func canvasRect(
        for windowID: CGWindowID,
        canvasSize: CGSize,
        coordinateSpace: WindowPlacementCoordinateSpace
    ) -> CGRect? {
        guard let placement = placements[windowID], placement.hasValidCropFrame else { return nil }
        if allowsOverflow {
            return WindowPlacementMath.canvasRectUnclamped(
                for: placement,
                canvasSize: canvasSize,
                coordinateSpace: coordinateSpace
            )
        }
        return WindowPlacementMath.canvasRect(
            for: placement,
            canvasSize: canvasSize,
            coordinateSpace: coordinateSpace
        )
    }

    private func updateAspects(for windowIDs: [CGWindowID]) {
        for windowID in windowIDs {
            if let window = WindowCaptureService.shared.scWindow(for: windowID),
               window.frame.width > 0 {
                windowAspects[windowID] = window.frame.height / window.frame.width
            }
        }
    }
}
