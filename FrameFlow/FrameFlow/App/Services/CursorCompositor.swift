//
//  CursorCompositor.swift
//  FrameFlow
//

import AppKit
import CoreGraphics
import CoreImage
import Foundation
import ScreenCaptureKit

@MainActor
enum CursorCompositor {
    private static var cachedCursorImage: CIImage?

    /// Returns a CIImage cursor overlay for the canvas, or nil if the cursor is not over a selected window.
    static func cursorOverlay(
        mouseLocation: CGPoint,
        activeWindowID: CGWindowID?,
        windowOrder: [CGWindowID],
        placements: [CGRect],
        canvasRect: CGRect
    ) -> CIImage? {
        guard let match = resolveCursorWindow(
            mouseLocation: mouseLocation,
            activeWindowID: activeWindowID,
            windowOrder: windowOrder
        ) else {
            return nil
        }

        guard match.index < placements.count else { return nil }
        guard let scWindow = WindowCaptureService.shared.scWindow(for: match.windowID) else { return nil }

        let windowFrame = scWindow.frame
        guard windowFrame.width > 0, windowFrame.height > 0 else { return nil }
        guard windowFrame.contains(mouseLocation) else { return nil }

        let normalizedX = (mouseLocation.x - windowFrame.minX) / windowFrame.width
        let normalizedY = (mouseLocation.y - windowFrame.minY) / windowFrame.height
        let placement = placements[match.index]
        let canvasPoint = CGPoint(
            x: placement.minX + normalizedX * placement.width,
            y: placement.minY + normalizedY * placement.height
        )

        return renderCursor(at: canvasPoint, canvasRect: canvasRect)
    }

    private static func resolveCursorWindow(
        mouseLocation: CGPoint,
        activeWindowID: CGWindowID?,
        windowOrder: [CGWindowID]
    ) -> (index: Int, windowID: CGWindowID)? {
        if let activeWindowID,
           let index = windowOrder.firstIndex(of: activeWindowID),
           let scWindow = WindowCaptureService.shared.scWindow(for: activeWindowID),
           scWindow.frame.contains(mouseLocation) {
            return (index, activeWindowID)
        }

        for windowID in windowOrder.reversed() {
            guard let index = windowOrder.firstIndex(of: windowID),
                  let scWindow = WindowCaptureService.shared.scWindow(for: windowID),
                  scWindow.frame.contains(mouseLocation) else {
                continue
            }
            return (index, windowID)
        }

        return nil
    }

    private static func renderCursor(at point: CGPoint, canvasRect: CGRect) -> CIImage? {
        guard let cursorImage = cursorCIImage() else { return nil }

        let hotSpot = NSCursor.arrow.hotSpot
        let extent = cursorImage.extent
        let originX = point.x - hotSpot.x
        let originY = point.y - hotSpot.y

        let positioned = cursorImage
            .transformed(by: CGAffineTransform(translationX: originX, y: originY))
            .cropped(to: canvasRect)

        return positioned
    }

    private static func cursorCIImage() -> CIImage? {
        if let cachedCursorImage {
            return cachedCursorImage
        }

        let size = NSSize(width: 32, height: 32)
        let image = NSImage(size: size)
        image.lockFocus()
        NSCursor.arrow.set()
        NSCursor.arrow.image.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1)
        image.unlockFocus()

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let ciImage = CIImage(cgImage: cgImage)
        cachedCursorImage = ciImage
        return ciImage
    }
}
