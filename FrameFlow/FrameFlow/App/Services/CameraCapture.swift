//
//  CameraCapture.swift
//  FrameFlow
//

import AVFoundation
import CoreImage
import CoreMedia
import Foundation

@MainActor
@Observable
final class CameraCapture {
    private(set) var latestFrame: CIImage?
    private(set) var isRunning = false
    private(set) var isUnavailable = false
    private(set) var statusMessage: String?
    private var hasReceivedFrameSinceStart = false

    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    /// All AVCaptureSession mutations (configure, start/stop, delegate wiring).
    private let sessionQueue = DispatchQueue(label: "com.Simranjit.FrameFlow.camera.session", qos: .userInitiated)
    /// Sample-buffer delivery only — never start/stop or reconfigure the session here.
    private let outputQueue = DispatchQueue(label: "com.Simranjit.FrameFlow.camera.capture", qos: .userInitiated)
    private var currentInput: AVCaptureDeviceInput?
    private var outputDelegate: CameraVideoOutputDelegate?
    /// Serializes start/stop so rapid PiP toggles cannot overlap session mutations.
    private var sessionOperation: Task<Void, Never>?
    private var disconnectObserver: NSObjectProtocol?

    var frameForComposite: CIImage? {
        guard isRunning, !isUnavailable, hasReceivedFrameSinceStart else { return nil }
        return latestFrame
    }

    func start(preferredCameraID: String?) async {
        await enqueueSessionOperation { [self] in
            let status = PermissionManager.shared.checkCameraPermission()
            if status == .notDetermined {
                let granted = await PermissionManager.shared.requestCameraPermission()
                guard granted else {
                    statusMessage = "Camera access denied. Recording continues without PiP."
                    return
                }
            } else if status != .authorized {
                statusMessage = "Camera access denied. Recording continues without PiP."
                return
            }

            let device = preferredDevice(for: preferredCameraID) ?? AVCaptureDevice.default(for: .video)
            guard let device else {
                statusMessage = "No camera available. Recording continues without PiP."
                return
            }

            if canReuseWarmSession(for: device) {
                isUnavailable = false
                statusMessage = nil
                #if DEBUG
                print(
                    "[CameraCapture] start: reusedWarmSession=true " +
                    "hasFrame=\(latestFrame != nil)"
                )
                #endif
                return
            }

            await performStopOnSessionQueue()

            let delegate = CameraVideoOutputDelegate { [weak self] image in
                Task { @MainActor [weak self] in
                    self?.latestFrame = image
                    self?.hasReceivedFrameSinceStart = true
                    self?.isUnavailable = false
                }
            }

            latestFrame = nil
            hasReceivedFrameSinceStart = false

            let startResult: SessionStartResult = await withCheckedContinuation { continuation in
                sessionQueue.async { [session, output, outputQueue] in
                    session.beginConfiguration()
                    session.sessionPreset = .high

                    do {
                        let input = try AVCaptureDeviceInput(device: device)
                        guard session.canAddInput(input) else {
                            session.commitConfiguration()
                            continuation.resume(returning: .configurationFailed(
                                "Could not configure camera input. Recording continues without PiP."
                            ))
                            return
                        }
                        session.addInput(input)

                        output.videoSettings = [
                            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                        ]
                        output.alwaysDiscardsLateVideoFrames = true
                        guard session.canAddOutput(output) else {
                            session.commitConfiguration()
                            continuation.resume(returning: .configurationFailed(
                                "Could not configure camera output. Recording continues without PiP."
                            ))
                            return
                        }
                        session.addOutput(output)

                        if let connection = output.connection(with: .video),
                           connection.isVideoMirroringSupported {
                            connection.isVideoMirrored = true
                        }

                        output.setSampleBufferDelegate(delegate, queue: outputQueue)
                        session.commitConfiguration()
                        session.startRunning()
                        continuation.resume(returning: .started(input))
                    } catch {
                        session.commitConfiguration()
                        continuation.resume(returning: .configurationFailed(
                            "Could not start camera capture. Recording continues without PiP."
                        ))
                    }
                }
            }

            switch startResult {
            case .started(let input):
                outputDelegate = delegate
                currentInput = input
                isRunning = true
                isUnavailable = false
                statusMessage = nil
                observeDisconnect(for: input.device)
            case .configurationFailed(let message):
                outputDelegate = nil
                currentInput = nil
                isRunning = false
                isUnavailable = true
                statusMessage = message
            }
        }
    }

    func stop() async {
        await enqueueSessionOperation { [self] in
            await performStopOnSessionQueue()
        }
    }

    // MARK: - Session lifecycle (serialized)

    private func enqueueSessionOperation(_ operation: @escaping () async -> Void) async {
        let previous = sessionOperation
        let task = Task { @MainActor in
            await previous?.value
            await operation()
        }
        sessionOperation = task
        await task.value
    }

    private func performStopOnSessionQueue() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async { [session, output] in
                output.setSampleBufferDelegate(nil, queue: nil)

                if session.isRunning {
                    session.stopRunning()
                }

                session.beginConfiguration()
                session.inputs.forEach { session.removeInput($0) }
                session.outputs.forEach { session.removeOutput($0) }
                session.commitConfiguration()

                continuation.resume()
            }
        }

        removeDisconnectObserver()
        outputDelegate = nil
        currentInput = nil
        latestFrame = nil
        hasReceivedFrameSinceStart = false
        isRunning = false
        isUnavailable = false
    }

    private func observeDisconnect(for device: AVCaptureDevice) {
        removeDisconnectObserver()
        disconnectObserver = NotificationCenter.default.addObserver(
            forName: AVCaptureDevice.wasDisconnectedNotification,
            object: device,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleDeviceDisconnected()
            }
        }
    }

    private func removeDisconnectObserver() {
        if let disconnectObserver {
            NotificationCenter.default.removeObserver(disconnectObserver)
        }
        disconnectObserver = nil
    }

    private func handleDeviceDisconnected() {
        isUnavailable = true
        latestFrame = nil
        hasReceivedFrameSinceStart = false
        isRunning = false
        statusMessage = "Camera disconnected. Recording continues with a PiP placeholder."
    }

    /// Skip teardown when layout picker or a prior start already warmed the same camera.
    private func canReuseWarmSession(for device: AVCaptureDevice) -> Bool {
        isRunning
            && !isUnavailable
            && hasReceivedFrameSinceStart
            && latestFrame != nil
            && currentInput?.device.uniqueID == device.uniqueID
    }

    private func preferredDevice(for cameraID: String?) -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        if let cameraID,
           let matching = discovery.devices.first(where: { $0.uniqueID == cameraID }) {
            return matching
        }
        return discovery.devices.first
    }

    private enum SessionStartResult {
        case started(AVCaptureDeviceInput)
        case configurationFailed(String)
    }
}

private final class CameraVideoOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let onFrame: (CIImage) -> Void

    init(onFrame: @escaping (CIImage) -> Void) {
        self.onFrame = onFrame
        super.init()
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let raw = CIImage(cvPixelBuffer: pixelBuffer)
        let normalized = CameraFrameOrientation.normalize(raw, mirrored: false)
        onFrame(normalized)
    }
}
