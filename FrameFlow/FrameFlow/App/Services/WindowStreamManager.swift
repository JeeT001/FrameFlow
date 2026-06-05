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

@MainActor
@Observable
final class WindowStreamManager {
    static let shared = WindowStreamManager()

    private(set) var latestFrames: [CGWindowID: CIImage] = [:]
    private(set) var isRunning = false
    private(set) var isSystemAudioRunning = false
    var lastErrorMessage: String?
    var onSystemAudioSampleBuffer: ((CMSampleBuffer) -> Void)?

    private var sessions: [CGWindowID: WindowStreamSession] = [:]
    private var systemAudioSession: SystemAudioStreamSession?
    private let capabilities = DeviceCapabilityManager.shared

    private init() {}

    func startAll(windowIDs: Set<CGWindowID>) async throws {
        await stopAll()

        guard !windowIDs.isEmpty else { return }

        guard await WindowCaptureService.shared.checkPermission() else {
            throw WindowStreamError.permissionDenied
        }

        do {
            for windowID in windowIDs.sorted() {
                guard let scWindow = WindowCaptureService.shared.scWindow(for: windowID) else {
                    throw WindowStreamError.missingWindow(windowID)
                }

                let session = try await WindowStreamSession.make(
                    window: scWindow,
                    frameRate: capabilities.compositeFrameRate,
                    onFrame: { [weak self] id, image in
                        Task { @MainActor in
                            self?.latestFrames[id] = image
                        }
                    }
                )
                sessions[windowID] = session
            }

            isRunning = true
            lastErrorMessage = nil
        } catch {
            await stopAllVideoStreams()
            throw error
        }
    }

    func startSystemAudioCapture() async throws {
        await stopSystemAudioCapture()

        guard await WindowCaptureService.shared.checkPermission() else {
            throw WindowStreamError.permissionDenied
        }

        do {
            let shareableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = shareableContent.displays.first else {
                throw WindowStreamError.startFailed("No display available for system audio capture.")
            }

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
        latestFrames = [:]
        isRunning = false
    }

    func stopAll() async {
        await stopAllVideoStreams()
        await stopSystemAudioCapture()
    }
}

private final class WindowStreamSession {
    private let stream: SCStream
    private let output: WindowStreamOutput
    private let handlerQueue: DispatchQueue

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

        return WindowStreamSession(stream: stream, output: output, handlerQueue: handlerQueue)
    }

    private init(stream: SCStream, output: WindowStreamOutput, handlerQueue: DispatchQueue) {
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
