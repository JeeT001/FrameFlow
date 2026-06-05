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
    let windowPlacementController = WindowPlacementController()

    var format: RecordingFormat = .sixteenByNine
    var layoutPreset: LayoutPreset = .stacked
    var cameraEnabled = false
    var selectedCameraID: String?
    var availableCameras: [AVCaptureDevice] = []

    var showAudioSheet = false
    var showUpgradeSheet = false
    var showNoWindowsAlert = false

    private let previewCoordinator = CompositePreviewCoordinator()
    private var previousLayoutPreset: LayoutPreset = .stacked

    var previewImage: CGImage? { previewCoordinator.previewImage }
    var previewErrorMessage: String? { previewCoordinator.errorMessage }
    var isLivePreviewActive: Bool { previewCoordinator.isLiveActive }
    var isStartingLivePreview: Bool { previewCoordinator.isStarting }
    var latestCameraFrame: CIImage? { cameraCapture.latestFrame }
    var pipPresets: [PiPPreset] { PiPPreset.allCases }

    var windowOrder: [CGWindowID] {
        previewWindowOrder
    }

    private var previewWindowOrder: [CGWindowID] = []

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
            AnalyticsService.trackFeatureBlocked(feature: "9_16_format")
            showUpgradeSheet = true
            return
        }
        format = newFormat
    }

    func loadSessionState(from appState: AppState) {
        if !appState.selectedWindowIDs.isEmpty {
            format = appState.selectedFormat
            layoutPreset = appState.selectedLayoutPreset
            previousLayoutPreset = layoutPreset
            previewWindowOrder = appState.selectedWindowIDs.sorted()
            if layoutPreset == .freeForm, !appState.windowPlacements.isEmpty {
                windowPlacementController.placements = appState.windowPlacements
            }
        }
        cameraEnabled = pipController.isCameraEnabled
        selectedCameraID = pipController.selectedCameraID
        syncFreeFormOverflowState()
    }

    func syncSessionState(to appState: AppState) {
        appState.selectedFormat = format
        appState.selectedLayoutPreset = layoutPreset
        if layoutPreset == .freeForm {
            appState.windowPlacements = windowPlacementController.placements
        } else {
            appState.windowPlacements = [:]
        }
    }

    func startLivePreview(appState: AppState) async {
        syncSessionState(to: appState)
        previewWindowOrder = appState.selectedWindowIDs.sorted()
        ensureFreeFormPlacementsIfNeeded(appState: appState)
        syncFreeFormOverflowState()
        await previewCoordinator.start(
            windowIDs: appState.selectedWindowIDs,
            format: format,
            layoutPreset: layoutPreset,
            placementsResolver: placementsResolver,
            windowAspects: currentWindowAspects(for: appState),
            autoFocusEnabled: settings.autoFocusEnabled
        )
    }

    func stopLivePreview() async {
        await previewCoordinator.stop()
        await cameraCapture.stop()
    }

    func refreshLivePreview(appState: AppState) async {
        syncSessionState(to: appState)
        previewWindowOrder = appState.selectedWindowIDs.sorted()
        ensureFreeFormPlacementsIfNeeded(appState: appState)
        normalizePiPForCurrentFormat()
        await previewCoordinator.updateWindowIDs(
            appState.selectedWindowIDs,
            format: format,
            layoutPreset: layoutPreset,
            placementsResolver: placementsResolver,
            windowAspects: currentWindowAspects(for: appState),
            autoFocusEnabled: settings.autoFocusEnabled
        )
    }

    func updateLivePreviewLayout(appState: AppState) {
        syncSessionState(to: appState)
        previewCoordinator.updateLayout(
            format: format,
            layoutPreset: layoutPreset,
            placementsResolver: placementsResolver,
            windowAspects: currentWindowAspects(for: appState),
            autoFocusEnabled: settings.autoFocusEnabled
        )
        normalizePiPForCurrentFormat()
    }

    func handleLayoutPresetChange(from oldPreset: LayoutPreset, to newPreset: LayoutPreset, appState: AppState) {
        let canvasSize = CompositeEngine.shared.outputSize(for: format)
        let windowIDs = appState.selectedWindowIDs.sorted()

        if newPreset == .freeForm {
            if oldPreset == .freeForm, !windowPlacementController.placements.isEmpty {
                // Keep existing free-form placements.
            } else if !appState.windowPlacements.isEmpty {
                windowPlacementController.placements = appState.windowPlacements
            } else {
                windowPlacementController.seedFreeFormDefault(
                    windowIDs: windowIDs,
                    canvasSize: canvasSize
                )
            }
        }

        previousLayoutPreset = oldPreset
        layoutPreset = newPreset
        syncFreeFormOverflowState()
        syncSessionState(to: appState)
        updateLivePreviewLayout(appState: appState)
    }

    func syncWindowPlacements(to appState: AppState) {
        syncSessionState(to: appState)
        updateLivePreviewLayout(appState: appState)
    }

    func setCameraEnabled(_ enabled: Bool) {
        cameraEnabled = enabled
        pipController.isCameraEnabled = enabled
        if !enabled {
            pipController.applyPreset(.noCamera)
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
        normalizePiPForCurrentFormat()
    }

    func syncPiPState() {
        pipController.isCameraEnabled = cameraEnabled
        pipController.selectedCameraID = selectedCameraID
    }

    func startCameraPreviewIfNeeded() async {
        guard cameraEnabled else {
            await cameraCapture.stop()
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

    private func ensureFreeFormPlacementsIfNeeded(appState: AppState) {
        guard layoutPreset == .freeForm else { return }

        let windowIDs = appState.selectedWindowIDs.sorted()
        guard !windowIDs.isEmpty else { return }

        let missingWindow = windowIDs.contains { windowPlacementController.placements[$0] == nil }
        if windowPlacementController.placements.isEmpty || missingWindow {
            if !appState.windowPlacements.isEmpty, !missingWindow {
                windowPlacementController.placements = appState.windowPlacements
            } else {
                windowPlacementController.seedFreeFormDefault(
                    windowIDs: windowIDs,
                    canvasSize: CompositeEngine.shared.outputSize(for: format)
                )
            }
        }
    }

    private var placementsResolver: () -> [CGWindowID: WindowPlacement] {
        { [windowPlacementController] in
            windowPlacementController.placements
        }
    }

    private func currentWindowAspects(for appState: AppState) -> [CGWindowID: CGFloat] {
        var aspects: [CGWindowID: CGFloat] = [:]
        for windowID in appState.selectedWindowIDs {
            aspects[windowID] = windowPlacementController.aspectRatio(for: windowID)
        }
        return aspects
    }

    private func normalizePiPForCurrentFormat() {
        guard !pipController.allowsOverflow else { return }
        pipController.normalizePositionForCanvas(format: format)
    }

    private func syncFreeFormOverflowState() {
        let isFreeForm = layoutPreset == .freeForm
        windowPlacementController.allowsOverflow = isFreeForm
        pipController.allowsOverflow = isFreeForm
        if isFreeForm {
            return
        }
        pipController.normalizePositionForCanvas(format: format)
    }
}
