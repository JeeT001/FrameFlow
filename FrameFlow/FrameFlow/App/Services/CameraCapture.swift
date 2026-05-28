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
    private let outputQueue = DispatchQueue(label: "com.Simranjit.FrameFlow.camera.capture", qos: .userInitiated)
    private var currentInput: AVCaptureDeviceInput?
    private var outputDelegate: CameraVideoOutputDelegate?

    func start(preferredCameraID: String?) async {
        stop()

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

        session.beginConfiguration()
        session.sessionPreset = .high
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        let device = preferredDevice(for: preferredCameraID) ?? AVCaptureDevice.default(for: .video)
        guard let device else {
            session.commitConfiguration()
            statusMessage = "No camera available. Recording continues without PiP."
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                session.commitConfiguration()
                statusMessage = "Could not configure camera input. Recording continues without PiP."
                return
            }
            session.addInput(input)
            currentInput = input

            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            output.alwaysDiscardsLateVideoFrames = true
            guard session.canAddOutput(output) else {
                session.commitConfiguration()
                statusMessage = "Could not configure camera output. Recording continues without PiP."
                return
            }
            session.addOutput(output)
            if let connection = output.connection(with: .video), connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }

            let delegate = CameraVideoOutputDelegate { [weak self] image in
                Task { @MainActor [weak self] in
                    self?.latestFrame = image
                }
            }
            output.setSampleBufferDelegate(delegate, queue: outputQueue)
            outputDelegate = delegate
            session.commitConfiguration()

            outputQueue.async { [session] in
                session.startRunning()
            }
            isRunning = true
            statusMessage = nil
        } catch {
            session.commitConfiguration()
            statusMessage = "Could not start camera capture. Recording continues without PiP."
        }
    }

    func stop() {
        if session.isRunning {
            outputQueue.async { [session] in
                session.stopRunning()
            }
        }
        output.setSampleBufferDelegate(nil, queue: nil)
        outputDelegate = nil
        currentInput = nil
        latestFrame = nil
        isRunning = false
    }

    private func preferredDevice(for cameraID: String?) -> AVCaptureDevice? {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        if let cameraID,
           let matching = session.devices.first(where: { $0.uniqueID == cameraID }) {
            return matching
        }
        return session.devices.first
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
