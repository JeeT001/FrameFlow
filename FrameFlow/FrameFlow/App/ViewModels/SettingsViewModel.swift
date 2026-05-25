//
//  SettingsViewModel.swift
//  FrameFlow
//

import AVFoundation
import Foundation

@Observable
final class SettingsViewModel {
    var screenRecordingGranted = false
    var cameraStatus: AVAuthorizationStatus = .notDetermined
    var microphoneStatus: AVAuthorizationStatus = .notDetermined
    var isRefreshing = false

    let capabilities = DeviceCapabilityManager.shared

    func refreshPermissions() async {
        isRefreshing = true
        defer { isRefreshing = false }

        screenRecordingGranted = await PermissionManager.shared.checkScreenRecordingPermission()
        cameraStatus = PermissionManager.shared.checkCameraPermission()
        microphoneStatus = PermissionManager.shared.checkMicrophonePermission()
    }

    func requestCameraAccess() async {
        _ = await PermissionManager.shared.requestCameraPermission()
        await refreshPermissions()
    }

    func requestMicrophoneAccess() async {
        _ = await PermissionManager.shared.requestMicrophonePermission()
        await refreshPermissions()
    }

    func screenRecordingStatusLabel() -> String {
        PermissionManager.shared.permissionStatusLabel(screenRecordingGranted: screenRecordingGranted)
    }

    func cameraStatusLabel() -> String {
        PermissionManager.shared.permissionStatusLabel(for: cameraStatus)
    }

    func microphoneStatusLabel() -> String {
        PermissionManager.shared.permissionStatusLabel(for: microphoneStatus)
    }
}
