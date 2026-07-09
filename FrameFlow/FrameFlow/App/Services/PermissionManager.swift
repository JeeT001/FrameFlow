//
//  PermissionManager.swift
//  FrameFlow
//

import AppKit
import AVFoundation
import Foundation
import ScreenCaptureKit

enum PermissionKind: CaseIterable {
    case screenRecording
    case camera
    case microphone

    var title: String {
        switch self {
        case .screenRecording: "Screen Recording"
        case .camera: "Camera"
        case .microphone: "Microphone"
        }
    }

    var settingsURL: URL {
        switch self {
        case .screenRecording:
            URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture")!
        case .camera:
            URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Camera")!
        case .microphone:
            URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Microphone")!
        }
    }
}

final class PermissionManager {
    static let shared = PermissionManager()

    private var cachedScreenRecordingGranted: Bool?

    private init() {}

    func markScreenRecordingGranted() {
        cachedScreenRecordingGranted = true
    }

    func checkScreenRecordingPermission() async -> Bool {
        if cachedScreenRecordingGranted == true {
            return true
        }

        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            cachedScreenRecordingGranted = true
            return true
        } catch {
            cachedScreenRecordingGranted = false
            return false
        }
    }

    func checkCameraPermission() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestCameraPermission() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    func checkMicrophonePermission() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }

    func requestMicrophonePermission() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    func openSystemSettings(for permission: PermissionKind) {
        NSWorkspace.shared.open(permission.settingsURL)
    }

    func permissionStatusLabel(for status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            "Granted"
        case .denied, .restricted:
            "Denied"
        case .notDetermined:
            "Not granted"
        @unknown default:
            "Not granted"
        }
    }

    func permissionStatusLabel(screenRecordingGranted: Bool) -> String {
        screenRecordingGranted ? "Granted" : "Not granted"
    }
}
