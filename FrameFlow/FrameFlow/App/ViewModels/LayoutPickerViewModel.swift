//
//  LayoutPickerViewModel.swift
//  FrameFlow
//

import AVFoundation
import CoreGraphics
import CoreImage
import Foundation
import ScreenCaptureKit

@Observable
@MainActor
final class LayoutPickerViewModel {
    let settings = SettingsStore.shared
    let pipController = PiPController.shared
    let cameraCapture = CameraCapture()

    var format: RecordingFormat = .sixteenByNine
    var layoutPreset: LayoutPreset = .stacked
    var cameraEnabled = false
    var selectedCameraID: String?
    var availableCameras: [AVCaptureDevice] = []

    var showAudioSheet = false
    var showUpgradeSheet = false
    var showNoWindowsAlert = false

    private let previewCoordinator = CompositePreviewCoordinator()

    var previewImage: CGImage? { previewCoordinator.previewImage }
    var previewErrorMessage: String? { previewCoordinator.errorMessage }
    var isLivePreviewActive: Bool { previewCoordinator.isLiveActive }
    var isStartingLivePreview: Bool { previewCoordinator.isStarting }
    var latestCameraFrame: CIImage? { cameraCapture.latestFrame }
    var pipPresets: [PiPPreset] { PiPPreset.allCases }

    var audioModeLabel: String {
        AudioModeOption(rawValue: settings.defaultAudioMode)?.title
            ?? settings.defaultAudioMode.capitalized
    }

    func selectedWindowCount(from appState: AppState) -> Int {
        appState.selectedWindowIDs.count
    }

    func windowLabels(from appState: AppState) -> [String] {
        let sortedIDs = appState.selectedWindowIDs.sorted()
        return sortedIDs.enumerated().map { index, id in
            if let window = WindowCaptureService.shared.scWindow(for: id) {
                let title = window.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !title.isEmpty { return title }
            }
            return "Window \(index + 1)"
        }
    }

    func loadCameras() {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        availableCameras = session.devices.sorted { $0.localizedName < $1.localizedName }
        if selectedCameraID == nil {
            selectedCameraID = availableCameras.first?.uniqueID
        }
    }

    func selectFormat(_ newFormat: RecordingFormat, isPro: Bool) {
        if newFormat == .nineBySixteen && !isPro {
            showUpgradeSheet = true
            return
        }
        format = newFormat
    }

    func loadSessionState(from appState: AppState) {
        if !appState.selectedWindowIDs.isEmpty {
            format = appState.selectedFormat
            layoutPreset = appState.selectedLayoutPreset
        }
        cameraEnabled = pipController.isCameraEnabled
        selectedCameraID = pipController.selectedCameraID
    }

    func syncSessionState(to appState: AppState) {
        appState.selectedFormat = format
        appState.selectedLayoutPreset = layoutPreset
    }

    func startLivePreview(appState: AppState) async {
        syncSessionState(to: appState)
        await previewCoordinator.start(
            windowIDs: appState.selectedWindowIDs,
            format: format,
            layoutPreset: layoutPreset
        )
    }

    func stopLivePreview() async {
        await previewCoordinator.stop()
        cameraCapture.stop()
    }

    func refreshLivePreview(appState: AppState) async {
        syncSessionState(to: appState)
        await previewCoordinator.updateWindowIDs(
            appState.selectedWindowIDs,
            format: format,
            layoutPreset: layoutPreset
        )
    }

    func updateLivePreviewLayout() {
        previewCoordinator.updateLayout(format: format, layoutPreset: layoutPreset)
    }

    func setCameraEnabled(_ enabled: Bool) {
        cameraEnabled = enabled
        pipController.isCameraEnabled = enabled
        if !enabled {
            pipController.applyPreset(.noCamera)
            cameraCapture.stop()
        } else if pipController.selectedPreset == .noCamera {
            pipController.applyPreset(.bottomRight)
        }
    }

    func setSelectedCameraID(_ cameraID: String?) {
        selectedCameraID = cameraID
        pipController.selectedCameraID = cameraID
    }

    func applyPiPPreset(_ preset: PiPPreset) {
        pipController.applyPreset(preset)
        cameraEnabled = pipController.isCameraEnabled
    }

    func syncPiPState() {
        pipController.isCameraEnabled = cameraEnabled
        pipController.selectedCameraID = selectedCameraID
    }

    func startCameraPreviewIfNeeded() async {
        guard cameraEnabled else {
            cameraCapture.stop()
            return
        }
        await cameraCapture.start(preferredCameraID: selectedCameraID)
    }

    func validateWindowsSelected(from appState: AppState) -> Bool {
        if appState.selectedWindowIDs.isEmpty {
            showNoWindowsAlert = true
            return false
        }
        return true
    }
}
