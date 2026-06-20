//
//  SettingsViewModel.swift
//  FrameFlow
//

import AVFoundation
import AppKit
import Foundation

@Observable
final class SettingsViewModel {
    let settings = SettingsStore.shared
    let capabilities = DeviceCapabilityManager.shared

    var screenRecordingGranted = false
    var cameraStatus: AVAuthorizationStatus = .notDetermined
    var microphoneStatus: AVAuthorizationStatus = .notDetermined
    var isRefreshing = false
    var audioInputDevices: [AVCaptureDevice] = []

    static let resolutionOptions = ["720p", "1080p", "4K"]
    static let audioModeOptions = ["mic", "system", "combined", "none"]
    static let captionStyleOptions = ["classic", "bold", "minimal"]
    static let cursorColorOptions = ["white", "yellow", "red"]
    static let appearanceOptions = ["system", "light", "dark"]

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

    func loadAudioDevices() {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        audioInputDevices = session.devices.sorted { $0.localizedName < $1.localizedName }
    }

    func chooseSaveFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Select the default folder for saved recordings."

        if panel.runModal() == .OK, let url = panel.url {
            settings.defaultSaveFolder = url.path
            do {
                let bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                settings.defaultSaveFolderBookmarkData = bookmark
            } catch {
                settings.defaultSaveFolderBookmarkData = nil
            }
        }
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

    var availableResolutions: [String] {
        capabilities.supports4K
            ? Self.resolutionOptions
            : Self.resolutionOptions.filter { $0 != "4K" }
    }

    var saveFolderNeedsReauthorization: Bool {
        settings.defaultSaveFolderBookmarkData == nil
    }

    var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    func appearanceLabel(for value: String) -> String {
        switch value {
        case "light": "Light"
        case "dark": "Dark"
        default: "System"
        }
    }

    func audioModeLabel(for value: String) -> String {
        switch value {
        case "mic": "Microphone"
        case "system": "System Audio"
        case "combined": "Combined"
        case "none": "None"
        default: value.capitalized
        }
    }

    func captionStyleLabel(for value: String) -> String {
        value.capitalized
    }

    func cursorColorLabel(for value: String) -> String {
        value.capitalized
    }
}
