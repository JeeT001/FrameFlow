//
//  CursorTracker.swift
//  FrameFlow
//

import AppKit
import Foundation

enum CursorClickType {
    case left
    case right
}

struct CursorClickEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let globalPoint: CGPoint
    let normalizedPoint: CGPoint
    let type: CursorClickType
}

@Observable
final class CursorTracker {
    private(set) var currentCursorPoint: CGPoint = .zero
    private(set) var normalizedCursorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
    private(set) var recentClicks: [CursorClickEvent] = []

    private var globalMoveMonitor: Any?
    private var localMoveMonitor: Any?
    private var globalLeftClickMonitor: Any?
    private var localLeftClickMonitor: Any?
    private var globalRightClickMonitor: Any?
    private var localRightClickMonitor: Any?

    func startTracking() {
        stopTracking()

        updateCursorPoint(NSEvent.mouseLocation)

        globalMoveMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.updateCursorPoint(event.locationInWindow)
            }
        }
        localMoveMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.updateCursorPoint(event.locationInWindow)
            }
            return event
        }

        globalLeftClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.registerClick(type: .left, at: event.locationInWindow)
            }
        }
        localLeftClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.registerClick(type: .left, at: event.locationInWindow)
            }
            return event
        }

        globalRightClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.registerClick(type: .right, at: event.locationInWindow)
            }
        }
        localRightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.registerClick(type: .right, at: event.locationInWindow)
            }
            return event
        }
    }

    func stopTracking() {
        if let globalMoveMonitor { NSEvent.removeMonitor(globalMoveMonitor) }
        if let localMoveMonitor { NSEvent.removeMonitor(localMoveMonitor) }
        if let globalLeftClickMonitor { NSEvent.removeMonitor(globalLeftClickMonitor) }
        if let localLeftClickMonitor { NSEvent.removeMonitor(localLeftClickMonitor) }
        if let globalRightClickMonitor { NSEvent.removeMonitor(globalRightClickMonitor) }
        if let localRightClickMonitor { NSEvent.removeMonitor(localRightClickMonitor) }

        globalMoveMonitor = nil
        localMoveMonitor = nil
        globalLeftClickMonitor = nil
        localLeftClickMonitor = nil
        globalRightClickMonitor = nil
        localRightClickMonitor = nil
        recentClicks = []
    }

    func pruneExpiredClicks(maxAge: TimeInterval = 0.8) {
        let threshold = Date().addingTimeInterval(-maxAge)
        recentClicks.removeAll { $0.timestamp < threshold }
    }

    deinit {
        let globalMoveMonitor = self.globalMoveMonitor
        let localMoveMonitor = self.localMoveMonitor
        let globalLeftClickMonitor = self.globalLeftClickMonitor
        let localLeftClickMonitor = self.localLeftClickMonitor
        let globalRightClickMonitor = self.globalRightClickMonitor
        let localRightClickMonitor = self.localRightClickMonitor
        DispatchQueue.main.async {
            if let globalMoveMonitor { NSEvent.removeMonitor(globalMoveMonitor) }
            if let localMoveMonitor { NSEvent.removeMonitor(localMoveMonitor) }
            if let globalLeftClickMonitor { NSEvent.removeMonitor(globalLeftClickMonitor) }
            if let localLeftClickMonitor { NSEvent.removeMonitor(localLeftClickMonitor) }
            if let globalRightClickMonitor { NSEvent.removeMonitor(globalRightClickMonitor) }
            if let localRightClickMonitor { NSEvent.removeMonitor(localRightClickMonitor) }
        }
    }

    private func updateCursorPoint(_ point: CGPoint) {
        currentCursorPoint = point
        normalizedCursorPoint = normalize(point: point)
    }

    private func registerClick(type: CursorClickType, at point: CGPoint) {
        updateCursorPoint(point)
        recentClicks.append(
            CursorClickEvent(
                timestamp: Date(),
                globalPoint: point,
                normalizedPoint: normalizedCursorPoint,
                type: type
            )
        )
        pruneExpiredClicks(maxAge: 2.0)
    }

    private func normalize(point: CGPoint) -> CGPoint {
        let allFrames = NSScreen.screens.map(\.frame)
        guard let first = allFrames.first else {
            return CGPoint(x: 0.5, y: 0.5)
        }
        let unionRect = allFrames.dropFirst().reduce(first) { $0.union($1) }
        guard unionRect.width > 0, unionRect.height > 0 else {
            return CGPoint(x: 0.5, y: 0.5)
        }
        let x = (point.x - unionRect.minX) / unionRect.width
        let y = (point.y - unionRect.minY) / unionRect.height
        return CGPoint(x: min(max(x, 0), 1), y: min(max(y, 0), 1))
    }
}
