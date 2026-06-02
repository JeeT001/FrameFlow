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
    private(set) var statusMessage: String?

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

    func start(preferredCameraID: String?) async {
        await enqueueSessionOperation { [self] in
            await performStopOnSessionQueue()

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

            let delegate = CameraVideoOutputDelegate { [weak self] image in
                Task { @MainActor [weak self] in
                    self?.latestFrame = image
                }
            }

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
                statusMessage = nil
            case .configurationFailed(let message):
                outputDelegate = nil
                currentInput = nil
                isRunning = false
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

        outputDelegate = nil
        currentInput = nil
        latestFrame = nil
        isRunning = false
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
        onFrame(CIImage(cvPixelBuffer: pixelBuffer))
    }
}
