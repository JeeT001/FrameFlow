//
//  RecordingSessionCoordinator.swift
//  FrameFlow
//

import CoreGraphics
import CoreImage
import Foundation
import ScreenCaptureKit

@MainActor
@Observable
final class RecordingSessionCoordinator {
    private(set) var previewImage: CGImage?
    private(set) var isStarting = false
    private(set) var isRecording = false
    var errorMessage: String?

    let engine = RecordingEngine()

    /// Latest zoom scale from `ZoomController` (updated each writer tick while recording).
    private(set) var displayZoomScale: CGFloat = 1.0

    private let streamManager = WindowStreamManager.shared
    private let compositeEngine = CompositeEngine.shared
    private let audioCaptureService = AudioCaptureService()
    private let cursorTracker = CursorTracker()
    private let zoomController = ZoomController()
    private let clickEffectRenderer = ClickEffectRenderer()
    private let activeWindowMonitor = ActiveWindowMonitor()
    private let pipController = PiPController.shared
    private let cameraCapture = CameraCapture()
    /// Recording composite + writer cadence (24 Hz — reduces CPU vs 30 Hz during PiP).
    static let recordFrameRate: Double = 24
    /// Live preview refresh (decoupled from writer — reuses last composite CIImage).
    private static let previewFrameRate: Double = 10
    private var displayTimer: Timer?
    private var previewTimer: Timer?
    private var lastCompositeCIImage: CIImage?

    private var windowOrder: [CGWindowID] = []
    private var format: RecordingFormat = .sixteenByNine
    private var layoutPreset: LayoutPreset = .stacked
    private var customPlacements: [CGWindowID: WindowPlacement] = [:]
    private var windowAspects: [CGWindowID: CGFloat] = [:]
    private var outputSize: CGSize = CGSize(width: 1280, height: 720)
    private var outputURL: URL?
    private var lastHandledClickID: UUID?
    private var autoFocusEnabled = false

    func startRecording(
        windowIDs: Set<CGWindowID>,
        format: RecordingFormat,
        preset: LayoutPreset,
        customPlacements: [CGWindowID: WindowPlacement] = [:],
        windowAspects: [CGWindowID: CGFloat] = [:],
        outputURL: URL,
        isPro: Bool
    ) async {
        await stopAll()

        guard !windowIDs.isEmpty else {
            errorMessage = "No windows selected."
            return
        }

        isStarting = true
        errorMessage = nil

        self.windowOrder = windowIDs.sorted()
        self.format = format
        self.layoutPreset = preset
        self.customPlacements = customPlacements
        self.windowAspects = windowAspects
        self.outputURL = outputURL

        outputSize = recordingOutputSize(format: format)
        pipController.normalizePositionForCanvas(format: format)

        let requestedMode = AudioModeOption(rawValue: SettingsStore.shared.defaultAudioMode) ?? .none
        let effectiveMode = effectiveAudioMode(requestedMode, isPro: isPro)
        // Hotfix: in `.combined` we currently prioritize microphone-only for the writer append path.
        // Combined mic+system buffers are not mixed into one PCM timeline yet, and interleaving can
        // still cause subtle A/V drift even with a shared video/audio PTS clock.
        let writerAudioMode: AudioModeOption = (effectiveMode == .combined) ? .mic : effectiveMode
        #if DEBUG
        if effectiveMode == .combined {
            print("[RecordingSessionCoordinator] Combined writer hotfix: using mic-only for A/V stability.")
        }
        #endif
        let shouldCaptureSystemAudio = (writerAudioMode == .system) && isPro
        let settings = SettingsStore.shared
        zoomController.configure(
            autoZoomOnClick: settings.autoZoomOnClick,
            zoomStrength: settings.zoomStrength,
            zoomHoldDuration: settings.zoomHoldDuration
        )
        autoFocusEnabled = settings.autoFocusEnabled
        cursorTracker.startTracking()
        if autoFocusEnabled {
            activeWindowMonitor.startMonitoring(selectedWindowIDs: windowIDs)
        }
        lastHandledClickID = nil
        lastCompositeCIImage = nil

        do {
            streamManager.onSystemAudioSampleBuffer = { [weak self] sampleBuffer in
                Task { @MainActor [weak self] in
                    self?.audioCaptureService.ingestSystemAudioSampleBuffer(sampleBuffer)
                }
            }
            try await streamManager.startAll(windowIDs: windowIDs)
            if shouldCaptureSystemAudio {
                try await streamManager.startSystemAudioCapture()
            }
            AudioCaptureDiagnostics.resetForRecording()
            try engine.start(outputURL: outputURL, outputSize: outputSize)
            if pipController.isCameraEnabled {
                await cameraCapture.start(preferredCameraID: pipController.selectedCameraID)
                if let cameraStatus = cameraCapture.statusMessage {
                    errorMessage = cameraStatus
                }
            } else {
                await cameraCapture.stop()
            }
            await audioCaptureService.start(
                mode: writerAudioMode,
                micVolume: SettingsStore.shared.defaultMicVolume,
                systemVolume: SettingsStore.shared.defaultSystemVolume,
                preferredMicDeviceUniqueID: SettingsStore.shared.defaultMicDevice
            ) { sampleBuffer, captureHostTime in
                do {
                    try self.engine.appendAudioSampleBuffer(sampleBuffer, captureHostTime: captureHostTime)
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
            if let audioStatus = audioCaptureService.statusMessage {
                errorMessage = audioStatus
            }
            isRecording = true
            startTimer()
        } catch {
            errorMessage = error.localizedDescription
            await stopAll()
        }

        isStarting = false
    }

    func updateLayout(format: RecordingFormat, preset: LayoutPreset) {
        self.format = format
        self.layoutPreset = preset
    }

    func pauseRecording() {
        guard isRecording else { return }
        engine.pauseRecording()
    }

    func resumeRecording() {
        guard isRecording else { return }
        engine.resumeRecording()
    }

    func zoomIn() {
        zoomController.zoomIn()
        displayZoomScale = zoomController.currentScale
    }

    func zoomOut() {
        zoomController.zoomOut()
        displayZoomScale = zoomController.currentScale
    }

    func resetZoom() {
        zoomController.resetZoom()
        displayZoomScale = zoomController.currentScale
    }

    func toggleAutoFocus() {
        let settings = SettingsStore.shared
        settings.autoFocusEnabled.toggle()
        setAutoFocusEnabled(settings.autoFocusEnabled)
    }

    func toggleCursorHighlight() {
        SettingsStore.shared.cursorHighlightEnabled.toggle()
    }

    func togglePiPCamera(isPro: Bool) async -> Bool {
        guard isPro else { return false }

        if pipController.isCameraEnabled {
            pipController.applyPreset(.noCamera)
            await cameraCapture.stop()
        } else {
            pipController.isCameraEnabled = true
            if pipController.selectedPreset == .noCamera {
                pipController.applyPreset(.bottomRight)
            }
            await cameraCapture.start(preferredCameraID: pipController.selectedCameraID)
            if let cameraStatus = cameraCapture.statusMessage {
                errorMessage = cameraStatus
            }
        }
        return true
    }

    private func setAutoFocusEnabled(_ enabled: Bool) {
        autoFocusEnabled = enabled
        if enabled, isRecording {
            activeWindowMonitor.startMonitoring(selectedWindowIDs: Set(windowOrder))
        } else {
            activeWindowMonitor.stopMonitoring()
        }
    }

    private func syncAutoFocusFromSettings() {
        let enabled = SettingsStore.shared.autoFocusEnabled
        guard enabled != autoFocusEnabled else { return }
        setAutoFocusEnabled(enabled)
    }

    func stopAll() async {
        displayTimer?.invalidate()
        displayTimer = nil
        previewTimer?.invalidate()
        previewTimer = nil
        lastCompositeCIImage = nil
        previewImage = nil
        cursorTracker.stopTracking()
        activeWindowMonitor.stopMonitoring()
        await cameraCapture.stop()
        audioCaptureService.stop()
        await streamManager.stopSystemAudioCapture()
        streamManager.onSystemAudioSampleBuffer = nil

        if isRecording {
            try? await engine.stop()
        }

        isRecording = false
        await streamManager.stopAllVideoStreams()
    }

    /// Finalizes the writer and moves the temp file to `destinationURL` (staging — no save-folder bookmark).
    func finalizeAndStop(moveTo destinationURL: URL) async throws -> URL {
        guard let currentOutputURL = outputURL else {
            await stopAll()
            throw RecordingEngineError.notRecording
        }

        try await engine.stop()
        cursorTracker.stopTracking()
        activeWindowMonitor.stopMonitoring()
        await cameraCapture.stop()
        audioCaptureService.stop()
        await streamManager.stopSystemAudioCapture()
        isRecording = false
        streamManager.onSystemAudioSampleBuffer = nil
        await streamManager.stopAllVideoStreams()
        displayTimer?.invalidate()
        displayTimer = nil
        previewTimer?.invalidate()
        previewTimer = nil
        lastCompositeCIImage = nil

        let fileManager = FileManager.default
        return try moveRecording(
            from: currentOutputURL,
            to: destinationURL,
            fileManager: fileManager,
            stopSecurityScopeOnFolderURL: nil
        )
    }

    private func startTimer() {
        displayTimer?.invalidate()
        previewTimer?.invalidate()

        previewTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / Self.previewFrameRate,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshPreviewIfNeeded()
            }
        }

        displayTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / Self.recordFrameRate,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.tick()
            }
        }
        Task { await tick() }
    }

    private func refreshPreviewIfNeeded() {
        guard isRecording, let ci = lastCompositeCIImage else { return }
        previewImage = compositeEngine.createCGImage(from: ci, canvasSize: outputSize)
    }

    private func tick() async {
        guard isRecording else { return }

        syncAutoFocusFromSettings()

        activeWindowMonitor.updateVisibleWindowIDs(Set(streamManager.latestFrames.keys))
        let zoomScale = currentZoomScale()
        let clickOverlay = currentClickOverlay()
        let focusedWindowID = autoFocusEnabled ? activeWindowMonitor.activeWindowID : nil
        let cursorWindowID = cursorTargetWindowID(focusedWindowID: focusedWindowID)
        let cameraFrame = cameraCapture.latestFrame
        let pipEnabled = pipController.isCameraEnabled
        let pipConfig = pipController.config
        let placements = layoutPreset == .freeForm ? customPlacements : nil

        let pipAllowsOverflow = layoutPreset == .freeForm

        await streamManager.updateCursorVisibility(activeWindowID: cursorWindowID)

        guard let ci = compositeEngine.renderCompositeCIImage(
            frames: streamManager.latestFrames,
            windowOrder: windowOrder,
            preset: layoutPreset,
            canvasSize: outputSize,
            zoomScale: zoomScale,
            zoomFocalPointNormalized: zoomController.focalPointNormalized,
            clickOverlay: clickOverlay,
            activeWindowID: focusedWindowID,
            autoFocusEnabled: autoFocusEnabled,
            customPlacements: placements,
            windowAspects: windowAspects,
            cameraFrame: cameraFrame,
            pipConfig: pipConfig,
            pipEnabled: pipEnabled,
            pipAllowsOverflow: pipAllowsOverflow
        ) else {
            return
        }

        lastCompositeCIImage = ci

        do {
            try engine.appendFrame(ciImage: ci, outputSize: outputSize)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func currentZoomScale() -> CGFloat {
        cursorTracker.pruneExpiredClicks()
        if let latestClick = cursorTracker.recentClicks.last, latestClick.id != lastHandledClickID {
            zoomController.handleClick(latestClick)
            lastHandledClickID = latestClick.id
        }
        zoomController.updateCursorPosition(normalizedPoint: cursorTracker.normalizedCursorPoint)
        zoomController.tick()
        let scale = zoomController.currentScale
        displayZoomScale = scale
        return scale
    }

    private func cursorTargetWindowID(focusedWindowID: CGWindowID?) -> CGWindowID? {
        let mouseLocation = cursorTracker.currentCursorPoint
        for windowID in windowOrder.reversed() {
            guard let scWindow = WindowCaptureService.shared.scWindow(for: windowID),
                  scWindow.frame.contains(mouseLocation) else {
                continue
            }
            return windowID
        }
        return focusedWindowID
    }

    private func currentClickOverlay() -> CIImage? {
        clickEffectRenderer.makeOverlay(
            clicks: cursorTracker.recentClicks,
            cursorNormalizedPoint: cursorTracker.normalizedCursorPoint,
            showCursorHighlight: SettingsStore.shared.cursorHighlightEnabled,
            cursorColorName: SettingsStore.shared.cursorHighlightColor,
            canvasSize: outputSize
        )
    }

    private func recordingOutputSize(format: RecordingFormat) -> CGSize {
        let prefers = SettingsStore.shared.defaultResolution.lowercased()
        let supports4K = DeviceCapabilityManager.shared.supports4K

        let landscape: CGSize
        switch prefers {
        case "4k":
            landscape = supports4K ? CGSize(width: 3840, height: 2160) : CGSize(width: 1920, height: 1080)
        case "720p":
            landscape = CGSize(width: 1280, height: 720)
        default:
            landscape = CGSize(width: 1920, height: 1080)
        }

        if format == .sixteenByNine {
            return landscape
        } else {
            return CGSize(width: landscape.height, height: landscape.width)
        }
    }

    private func effectiveAudioMode(_ requestedMode: AudioModeOption, isPro: Bool) -> AudioModeOption {
        guard requestedMode.requiresPro, !isPro else { return requestedMode }
        errorMessage = "System audio capture requires Pro. Continuing with microphone audio."
        return .mic
    }

    private func moveRecording(
        from sourceURL: URL,
        to destinationURL: URL,
        fileManager: FileManager,
        stopSecurityScopeOnFolderURL folderURLToStop: URL?
    ) throws -> URL {
        defer {
            folderURLToStop?.stopAccessingSecurityScopedResource()
        }

        try fileManager.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }
}

