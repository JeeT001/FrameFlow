//
//  ZoomController.swift
//  FrameFlow
//

import CoreGraphics
import Foundation

@MainActor
@Observable
final class ZoomController {
    private(set) var currentScale: CGFloat = 1.0
    private(set) var focalPointNormalized: CGPoint = CGPoint(x: 0.5, y: 0.5)

    private var autoZoomOnClick = false
    private var targetScale: CGFloat = 1.75
    private var holdDuration: TimeInterval = 1.0
    private var animation: ZoomAnimationState = .idle

    func configure(autoZoomOnClick: Bool, zoomStrength: Float, zoomHoldDuration: Double) {
        self.autoZoomOnClick = autoZoomOnClick
        self.targetScale = min(4, max(1, 1 + CGFloat(max(0, zoomStrength))))
        self.holdDuration = max(0.1, zoomHoldDuration)

        if !autoZoomOnClick {
            animation = .idle
            currentScale = 1
        }
    }

    func updateCursorPosition(normalizedPoint: CGPoint) {
        focalPointNormalized = clamped(normalizedPoint)
    }

    func handleClick(_ event: CursorClickEvent) {
        guard autoZoomOnClick else { return }

        focalPointNormalized = clamped(event.normalizedPoint)
        animation = .zoomingIn(
            startTime: event.timestamp,
            duration: 0.25,
            fromScale: currentScale,
            toScale: targetScale
        )
    }

    func tick(now: Date = Date()) {
        guard autoZoomOnClick else {
            currentScale = 1
            animation = .idle
            return
        }

        switch animation {
        case .idle:
            currentScale = 1

        case .zoomingIn(let startTime, let duration, let fromScale, let toScale):
            let progress = normalizedProgress(from: startTime, duration: duration, now: now)
            currentScale = interpolate(from: fromScale, to: toScale, t: easeInOut(progress))
            if progress >= 1 {
                animation = .holding(until: startTime.addingTimeInterval(duration + holdDuration), atScale: toScale)
            }

        case .holding(let until, let atScale):
            currentScale = atScale
            if now >= until {
                animation = .zoomingOut(
                    startTime: until,
                    duration: 0.35,
                    fromScale: atScale,
                    toScale: 1
                )
            }

        case .zoomingOut(let startTime, let duration, let fromScale, let toScale):
            let progress = normalizedProgress(from: startTime, duration: duration, now: now)
            currentScale = interpolate(from: fromScale, to: toScale, t: easeOutSpring(progress))
            if progress >= 1 {
                currentScale = 1
                animation = .idle
            }
        }
    }

    private func clamped(_ point: CGPoint) -> CGPoint {
        CGPoint(x: min(max(point.x, 0), 1), y: min(max(point.y, 0), 1))
    }

    private func normalizedProgress(from start: Date, duration: TimeInterval, now: Date) -> CGFloat {
        guard duration > 0 else { return 1 }
        let raw = now.timeIntervalSince(start) / duration
        return min(1, max(0, raw))
    }

    private func interpolate(from: CGFloat, to: CGFloat, t: CGFloat) -> CGFloat {
        from + (to - from) * t
    }

    private func easeInOut(_ t: CGFloat) -> CGFloat {
        if t < 0.5 {
            return 4 * t * t * t
        } else {
            let f = (2 * t) - 2
            return 0.5 * f * f * f + 1
        }
    }

    private func easeOutSpring(_ t: CGFloat) -> CGFloat {
        // Lightweight deterministic spring-ish easing without dynamic simulation.
        let clamped = min(max(t, 0), 1)
        let overshoot: CGFloat = 1.70158
        let shifted = clamped - 1
        return 1 + (overshoot + 1) * shifted * shifted * shifted + overshoot * shifted * shifted
    }
}

private enum ZoomAnimationState {
    case idle
    case zoomingIn(startTime: Date, duration: TimeInterval, fromScale: CGFloat, toScale: CGFloat)
    case holding(until: Date, atScale: CGFloat)
    case zoomingOut(startTime: Date, duration: TimeInterval, fromScale: CGFloat, toScale: CGFloat)
}
