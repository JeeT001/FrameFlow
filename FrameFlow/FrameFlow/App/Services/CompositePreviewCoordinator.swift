//
//  CompositePreviewCoordinator.swift
//  FrameFlow
//

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
    private var displayTimer: Timer?
    private var windowOrder: [CGWindowID] = []
    private var format: RecordingFormat = .sixteenByNine
    private var layoutPreset: LayoutPreset = .stacked

    func start(windowIDs: Set<CGWindowID>, format: RecordingFormat, layoutPreset: LayoutPreset) async {
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
        windowOrder = windowIDs.sorted()

        do {
            try await streamManager.startAll(windowIDs: windowIDs)
            isLiveActive = true
            startDisplayTimer()
        } catch {
            isLiveActive = false
            errorMessage = error.localizedDescription
            previewImage = nil
        }
    }

    func updateLayout(format: RecordingFormat, layoutPreset: LayoutPreset) {
        self.format = format
        self.layoutPreset = layoutPreset
        refreshCompositeFrame()
    }

    func updateWindowIDs(_ windowIDs: Set<CGWindowID>, format: RecordingFormat, layoutPreset: LayoutPreset) async {
        let sorted = windowIDs.sorted()
        guard sorted != windowOrder else {
            updateLayout(format: format, layoutPreset: layoutPreset)
            return
        }
        await start(windowIDs: windowIDs, format: format, layoutPreset: layoutPreset)
    }

    func stop() async {
        displayTimer?.invalidate()
        displayTimer = nil
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

        previewImage = compositeEngine.renderComposite(
            frames: streamManager.latestFrames,
            windowOrder: windowOrder,
            preset: layoutPreset,
            format: format
        )
    }
}
