//
//  WindowStreamManager.swift
//  FrameFlow
//

import CoreGraphics
import CoreImage
import CoreMedia
import CoreVideo
import Foundation
import ScreenCaptureKit

enum WindowStreamError: LocalizedError {
    case permissionDenied
    case missingWindow(CGWindowID)
    case startFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Screen recording permission is required for live preview."
        case .missingWindow(let id):
            "Window \(id) is no longer available. Return to the Window Picker and refresh."
        case .startFailed(let message):
            message
        }
    }
}

/// Thread-safe latest window frames — updated on SCStream queues, read on MainActor tick.
private final class WindowFrameBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var latest: [CGWindowID: CIImage] = [:]
    private var lastKnown: [CGWindowID: CIImage] = [:]

    func record(windowID: CGWindowID, image: CIImage) {
        lock.lock()
        defer { lock.unlock() }
        latest[windowID] = image
        lastKnown[windowID] = image
    }

    func snapshot() -> (latest: [CGWindowID: CIImage], lastKnown: [CGWindowID: CIImage]) {
        lock.lock()
        defer { lock.unlock() }
        return (latest, lastKnown)
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        latest.removeAll()
        lastKnown.removeAll()
    }
}

@MainActor
@Observable
final class WindowStreamManager {
    static let shared = WindowStreamManager()

    private let frameBuffer = WindowFrameBuffer()

    var latestFrames: [CGWindowID: CIImage] {
        frameBuffer.snapshot().latest
    }

    var lastKnownFrames: [CGWindowID: CIImage] {
        frameBuffer.snapshot().lastKnown
    }

    private(set) var isRunning = false
    private(set) var isSystemAudioRunning = false
    var lastErrorMessage: String?
    var onSystemAudioSampleBuffer: ((CMSampleBuffer) -> Void)?

    private var sessions: [CGWindowID: WindowStreamSession] = [:]
    private var systemAudioSession: SystemAudioStreamSession?
    private var cachedPrimaryDisplay: SCDisplay?
    private let capabilities = DeviceCapabilityManager.shared

    private init() {}

    var runningWindowIDs: Set<CGWindowID> {
        Set(sessions.keys)
    }

    func matchesRunningStreams(windowIDs: Set<CGWindowID>) -> Bool {
        isRunning && runningWindowIDs == windowIDs
    }

    func startAll(
        windowIDs: Set<CGWindowID>,
        captureFrameRate: Int? = nil
    ) async throws {
        let frameRate = captureFrameRate ?? capabilities.compositeFrameRate
        let sortedIDs = windowIDs.sorted()
        let targetIDs = Set(sortedIDs)

        guard !targetIDs.isEmpty else { return }

        if isRunning, runningWindowIDs == targetIDs {
            Task { await updateCaptureFrameRate(frameRate) }
            lastErrorMessage = nil
            return
        }

        guard await WindowCaptureService.shared.checkPermission() else {
            throw WindowStreamError.permissionDenied
        }

        await stopAll()

        let buffer = frameBuffer

        do {
            try await withThrowingTaskGroup(of: (CGWindowID, WindowStreamSession).self) { group in
                for windowID in sortedIDs {
                    group.addTask { @MainActor in
                        guard let scWindow = WindowCaptureService.shared.scWindow(for: windowID) else {
                            throw WindowStreamError.missingWindow(windowID)
                        }

                        let session = try await WindowStreamSession.make(
                            window: scWindow,
                            frameRate: frameRate,
                            onFrame: { id, image in
                                buffer.record(windowID: id, image: image)
                            }
                        )
                        return (windowID, session)
                    }
                }

                for try await (windowID, session) in group {
                    sessions[windowID] = session
                }
            }

            isRunning = true
            lastErrorMessage = nil
            PermissionManager.shared.markScreenRecordingGranted()
        } catch {
            await stopAllVideoStreams()
            throw error
        }
    }

    private func updateCaptureFrameRate(_ frameRate: Int) async {
        await withTaskGroup(of: Void.self) { group in
            for session in sessions.values {
                group.addTask {
                    await session.updateFrameRate(frameRate)
                }
            }
        }
    }

    /// Prefetch display metadata while the user is on the layout picker (avoids slow SCShareableContent on Record).
    func warmForRecording() async {
        if isRunning {
            PermissionManager.shared.markScreenRecordingGranted()
        }
        _ = try? await primaryDisplay()
    }

    func startSystemAudioCapture() async throws {
        await stopSystemAudioCapture()

        if !isRunning {
            guard await WindowCaptureService.shared.checkPermission() else {
                throw WindowStreamError.permissionDenied
            }
        }

        do {
            let display = try await primaryDisplay()

            systemAudioSession = try await SystemAudioStreamSession.make(
                display: display,
                onAudioSampleBuffer: { [weak self] sampleBuffer in
                    self?.onSystemAudioSampleBuffer?(sampleBuffer)
                }
            )
            isSystemAudioRunning = true
            lastErrorMessage = nil
        } catch {
            isSystemAudioRunning = false
            throw WindowStreamError.startFailed(error.localizedDescription)
        }
    }

    private func primaryDisplay() async throws -> SCDisplay {
        if let cachedPrimaryDisplay {
            return cachedPrimaryDisplay
        }

        let shareableContent = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        guard let display = shareableContent.displays.first else {
            throw WindowStreamError.startFailed("No display available for system audio capture.")
        }
        cachedPrimaryDisplay = display
        PermissionManager.shared.markScreenRecordingGranted()
        return display
    }

    func stopSystemAudioCapture() async {
        if let systemAudioSession {
            await systemAudioSession.stop()
        }
        systemAudioSession = nil
        isSystemAudioRunning = false
    }

    func stopAllVideoStreams() async {
        for (_, session) in sessions {
            await session.stop()
        }
        sessions.removeAll()
        frameBuffer.clear()
        isRunning = false
    }

    func isWindowAvailable(_ windowID: CGWindowID) -> Bool {
        WindowCaptureService.shared.scWindow(for: windowID) != nil
    }

    func stopAll() async {
        await stopAllVideoStreams()
        await stopSystemAudioCapture()
    }

    func updateCursorVisibility(activeWindowID: CGWindowID?) async {
        for (windowID, session) in sessions {
            let shouldShow = activeWindowID.map { windowID == $0 } ?? false
            await session.setShowsCursor(shouldShow)
        }
    }
}

private final class WindowStreamSession {
    private let stream: SCStream
    private let output: WindowStreamOutput
    private let handlerQueue: DispatchQueue
    private var configuration: SCStreamConfiguration
    private var showsCursorEnabled = false

    static func make(
        window: SCWindow,
        frameRate: Int,
        onFrame: @escaping (CGWindowID, CIImage) -> Void
    ) async throws -> WindowStreamSession {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        configuration.showsCursor = false
        configuration.capturesAudio = false
        configuration.pixelFormat = kCVPixelFormatType_32BGRA

        let frameWidth = max(2, Int(window.frame.width.rounded()))
        let frameHeight = max(2, Int(window.frame.height.rounded()))
        configuration.width = frameWidth
        configuration.height = frameHeight
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: Int32(max(frameRate, 1)))

        let handlerQueue = DispatchQueue(
            label: "com.Simranjit.FrameFlow.stream.\(window.windowID)",
            qos: .userInitiated
        )
        let output = WindowStreamOutput(
            windowID: window.windowID,
            queue: handlerQueue,
            onFrame: onFrame
        )
        let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)

        try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: handlerQueue)
        try await stream.startCapture()

        return WindowStreamSession(
            stream: stream,
            output: output,
            handlerQueue: handlerQueue,
            configuration: configuration
        )
    }

    private init(
        stream: SCStream,
        output: WindowStreamOutput,
        handlerQueue: DispatchQueue,
        configuration: SCStreamConfiguration
    ) {
        self.stream = stream
        self.output = output
        self.handlerQueue = handlerQueue
        self.configuration = configuration
        self.showsCursorEnabled = configuration.showsCursor
    }

    func setShowsCursor(_ enabled: Bool) async {
        guard enabled != showsCursorEnabled else { return }
        showsCursorEnabled = enabled
        configuration.showsCursor = enabled
        do {
            try await stream.updateConfiguration(configuration)
        } catch {
            showsCursorEnabled = !enabled
            configuration.showsCursor = !enabled
        }
    }

    func stop() async {
        do {
            try await stream.stopCapture()
        } catch {
            // Best-effort stop during teardown.
        }
    }

    func updateFrameRate(_ frameRate: Int) async {
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: Int32(max(frameRate, 1)))
        do {
            try await stream.updateConfiguration(configuration)
        } catch {
            // Keep existing capture rate if reconfiguration fails.
        }
    }
}

private final class WindowStreamOutput: NSObject, SCStreamOutput {
    private let windowID: CGWindowID
    private let onFrame: (CGWindowID, CIImage) -> Void

    init(
        windowID: CGWindowID,
        queue: DispatchQueue,
        onFrame: @escaping (CGWindowID, CIImage) -> Void
    ) {
        self.windowID = windowID
        self.onFrame = onFrame
        super.init()
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard CMSampleBufferIsValid(sampleBuffer) else { return }

        guard outputType == .screen,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let image = CIImage(cvPixelBuffer: pixelBuffer)
        onFrame(windowID, image)
    }
}

private final class SystemAudioStreamSession {
    private let stream: SCStream
    private let output: SystemAudioStreamOutput
    private let handlerQueue: DispatchQueue

    static func make(
        display: SCDisplay,
        onAudioSampleBuffer: @escaping (CMSampleBuffer) -> Void
    ) async throws -> SystemAudioStreamSession {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = true
        configuration.sampleRate = 48_000
        configuration.channelCount = 2
        configuration.width = 2
        configuration.height = 2
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        configuration.showsCursor = false

        let handlerQueue = DispatchQueue(
            label: "com.Simranjit.FrameFlow.system-audio",
            qos: .userInitiated
        )
        let output = SystemAudioStreamOutput(onAudioSampleBuffer: onAudioSampleBuffer)
        let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
        try stream.addStreamOutput(output, type: .audio, sampleHandlerQueue: handlerQueue)
        try await stream.startCapture()
        return SystemAudioStreamSession(stream: stream, output: output, handlerQueue: handlerQueue)
    }

    private init(stream: SCStream, output: SystemAudioStreamOutput, handlerQueue: DispatchQueue) {
        self.stream = stream
        self.output = output
        self.handlerQueue = handlerQueue
    }

    func stop() async {
        do {
            try await stream.stopCapture()
        } catch {
            // Best-effort stop during teardown.
        }
    }
}

private final class SystemAudioStreamOutput: NSObject, SCStreamOutput {
    private let onAudioSampleBuffer: (CMSampleBuffer) -> Void

    init(onAudioSampleBuffer: @escaping (CMSampleBuffer) -> Void) {
        self.onAudioSampleBuffer = onAudioSampleBuffer
        super.init()
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard outputType == .audio, CMSampleBufferIsValid(sampleBuffer) else { return }
        onAudioSampleBuffer(sampleBuffer)
    }
}
