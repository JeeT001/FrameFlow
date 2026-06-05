//
//  CompositePreviewCoordinator.swift
//  FrameFlow
//

import AppKit
import CoreGraphics
import Foundation

@MainActor
@Observable
final class CompositePreviewCoordinator {
    private(set) var previewImage: CGImage?
    private(set) var isLiveActive = false
    private(set) var isStarting = false
    var errorMessage: String?

    private let streamManager = WindowStreamManager.shared
    private let compositeEngine = CompositeEngine.shared
    private let cursorTracker = CursorTracker()
    private let activeWindowMonitor = ActiveWindowMonitor()
    private var displayTimer: Timer?
    private var windowOrder: [CGWindowID] = []
    private var format: RecordingFormat = .sixteenByNine
    private var layoutPreset: LayoutPreset = .stacked
    private var windowAspects: [CGWindowID: CGFloat] = [:]
    private var autoFocusEnabled = false
    private var placementsResolver: (() -> [CGWindowID: WindowPlacement])?

    func start(
        windowIDs: Set<CGWindowID>,
        format: RecordingFormat,
        layoutPreset: LayoutPreset,
        placementsResolver: (() -> [CGWindowID: WindowPlacement])? = nil,
        windowAspects: [CGWindowID: CGFloat] = [:],
        autoFocusEnabled: Bool = false
    ) async {
        await stop()

        guard !windowIDs.isEmpty else {
            errorMessage = nil
            previewImage = nil
            return
        }

        isStarting = true
        errorMessage = nil
        defer { isStarting = false }

        self.format = format
        self.layoutPreset = layoutPreset
        self.placementsResolver = placementsResolver
        self.windowAspects = windowAspects
        self.autoFocusEnabled = autoFocusEnabled
        windowOrder = windowIDs.sorted()

        cursorTracker.startTracking()
        activeWindowMonitor.startMonitoring(selectedWindowIDs: windowIDs)

        do {
            try await streamManager.startAll(windowIDs: windowIDs)
            isLiveActive = true
            startDisplayTimer()
        } catch {
            isLiveActive = false
            errorMessage = error.localizedDescription
            previewImage = nil
            cursorTracker.stopTracking()
            activeWindowMonitor.stopMonitoring()
        }
    }

    func updateLayout(
        format: RecordingFormat,
        layoutPreset: LayoutPreset,
        placementsResolver: (() -> [CGWindowID: WindowPlacement])?,
        windowAspects: [CGWindowID: CGFloat],
        autoFocusEnabled: Bool
    ) {
        self.format = format
        self.layoutPreset = layoutPreset
        self.placementsResolver = placementsResolver
        self.windowAspects = windowAspects
        self.autoFocusEnabled = autoFocusEnabled
        refreshCompositeFrame()
    }

    func updateWindowIDs(
        _ windowIDs: Set<CGWindowID>,
        format: RecordingFormat,
        layoutPreset: LayoutPreset,
        placementsResolver: (() -> [CGWindowID: WindowPlacement])?,
        windowAspects: [CGWindowID: CGFloat],
        autoFocusEnabled: Bool
    ) async {
        let sorted = windowIDs.sorted()
        guard sorted != windowOrder else {
            updateLayout(
                format: format,
                layoutPreset: layoutPreset,
                placementsResolver: placementsResolver,
                windowAspects: windowAspects,
                autoFocusEnabled: autoFocusEnabled
            )
            return
        }
        await start(
            windowIDs: windowIDs,
            format: format,
            layoutPreset: layoutPreset,
            placementsResolver: placementsResolver,
            windowAspects: windowAspects,
            autoFocusEnabled: autoFocusEnabled
        )
    }

    func stop() async {
        displayTimer?.invalidate()
        displayTimer = nil
        cursorTracker.stopTracking()
        activeWindowMonitor.stopMonitoring()
        await streamManager.stopAll()
        isLiveActive = false
        isStarting = false
        previewImage = nil
    }

    private func startDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshCompositeFrame()
            }
        }
        refreshCompositeFrame()
    }

    private func refreshCompositeFrame() {
        guard isLiveActive else { return }

        activeWindowMonitor.updateVisibleWindowIDs(Set(streamManager.latestFrames.keys))
        let canvasSize = compositeEngine.outputSize(for: format)
        let placements = layoutPreset == .freeForm ? placementsResolver?() : nil
        let focusedWindowID = autoFocusEnabled ? activeWindowMonitor.activeWindowID : nil

        previewImage = compositeEngine.renderComposite(
            frames: streamManager.latestFrames,
            windowOrder: windowOrder,
            preset: layoutPreset,
            canvasSize: canvasSize,
            mouseLocation: cursorTracker.currentCursorPoint,
            activeWindowID: focusedWindowID,
            autoFocusEnabled: autoFocusEnabled,
            customPlacements: placements,
            windowAspects: windowAspects,
            pipAllowsOverflow: layoutPreset == .freeForm
        )
    }
}
