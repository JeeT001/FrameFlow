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
    var platformPreviewOverlay: PlatformPreviewOverlay = .none
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
        refreshAvailableCameras()
        ensureValidCameraSelection()
    }

    func selectFormat(_ newFormat: RecordingFormat, isPro: Bool) {
        if newFormat == .nineBySixteen && !isPro {
            AnalyticsService.trackFeatureBlocked(feature: "9_16_format")
            showUpgradeSheet = true
            return
        }
        format = newFormat
    }

    func handleFormatChange(from oldFormat: RecordingFormat, to newFormat: RecordingFormat, appState: AppState) {
        if newFormat != .nineBySixteen {
            platformPreviewOverlay = .none
        }
        if newFormat == .nineBySixteen,
           layoutPreset == .freeForm,
           oldFormat != newFormat {
            let windowIDs = appState.selectedWindowIDs.sorted()
            if !windowIDs.isEmpty {
                windowPlacementController.seedFreeFormDefault(
                    windowIDs: windowIDs,
                    canvasSize: CompositeEngine.shared.outputSize(for: newFormat)
                )
                appState.windowPlacements = windowPlacementController.placements
            }
        }
        syncSessionState(to: appState)
        updateLivePreviewLayout(appState: appState)
    }

    func loadSessionState(from appState: AppState) {
        if !appState.selectedWindowIDs.isEmpty {
            format = appState.selectedFormat
            layoutPreset = appState.selectedLayoutPreset
            previousLayoutPreset = layoutPreset
            previewWindowOrder = appState.selectedWindowIDs.sorted()
            if layoutPreset == .freeForm, !appState.windowPlacements.isEmpty {
                if let valid = validFreeFormPlacements(
                    from: appState.windowPlacements,
                    windowIDs: previewWindowOrder
                ) {
                    windowPlacementController.placements = valid
                }
            }
        }
        cameraEnabled = pipController.isCameraEnabled
        selectedCameraID = pipController.selectedCameraID
        ensureValidCameraSelection()
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
        previewCoordinator.onCaptureFramesUpdated = { [windowPlacementController] frames in
            for (windowID, image) in frames {
                windowPlacementController.updateAspectFromCapture(windowID: windowID, image: image)
            }
        }
        configurePiPPreviewCoordinator()
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
        configurePiPPreviewCoordinator()
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
            if oldPreset == .freeForm, !windowPlacementController.needsFreeFormReseed(for: windowIDs) {
                // Keep existing free-form placements while user is mid-edit.
            } else {
                windowPlacementController.seedFreeFormDefault(
                    windowIDs: windowIDs,
                    canvasSize: canvasSize
                )
                appState.windowPlacements = windowPlacementController.placements
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

    func notifyPiPChanged(appState: AppState) {
        syncSessionState(to: appState)
        previewCoordinator.refreshPreviewFrame()
    }

    func setCameraEnabled(_ enabled: Bool) {
        cameraEnabled = enabled
        pipController.isCameraEnabled = enabled
        if !enabled {
            pipController.applyPreset(.noCamera)
        } else {
            if pipController.selectedPreset == .noCamera {
                pipController.applyPreset(.bottomRight)
            }
            ensureValidCameraSelection()
        }
        previewCoordinator.refreshPreviewFrame()
    }

    func setSelectedCameraID(_ cameraID: String?) {
        selectedCameraID = cameraID
        pipController.selectedCameraID = cameraID
    }

    func applyPiPPreset(_ preset: PiPPreset, appState: AppState) {
        pipController.applyPreset(preset)
        cameraEnabled = pipController.isCameraEnabled
        normalizePiPForCurrentFormat()
        updateLivePreviewLayout(appState: appState)
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

    private func refreshAvailableCameras() {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        availableCameras = session.devices.sorted { $0.localizedName < $1.localizedName }
    }

    private func ensureValidCameraSelection() {
        if availableCameras.isEmpty {
            refreshAvailableCameras()
        }
        let isValid = selectedCameraID.flatMap { id in
            availableCameras.contains(where: { $0.uniqueID == id })
        } ?? false
        if !isValid {
            selectedCameraID = availableCameras.first?.uniqueID
        }
        pipController.selectedCameraID = selectedCameraID
    }

    private func ensureFreeFormPlacementsIfNeeded(appState: AppState) {
        guard layoutPreset == .freeForm else { return }

        let windowIDs = appState.selectedWindowIDs.sorted()
        guard !windowIDs.isEmpty else { return }

        if windowPlacementController.needsFreeFormReseed(for: windowIDs) {
            windowPlacementController.seedFreeFormDefault(
                windowIDs: windowIDs,
                canvasSize: CompositeEngine.shared.outputSize(for: format)
            )
            appState.windowPlacements = windowPlacementController.placements
        }
    }

    private func validFreeFormPlacements(
        from stored: [CGWindowID: WindowPlacement],
        windowIDs: [CGWindowID]
    ) -> [CGWindowID: WindowPlacement]? {
        guard !windowIDs.isEmpty else { return nil }
        var result: [CGWindowID: WindowPlacement] = [:]
        for windowID in windowIDs {
            guard let placement = stored[windowID], placement.hasValidCropFrame else {
                return nil
            }
            result[windowID] = placement
        }
        return result
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

    private func configurePiPPreviewCoordinator() {
        previewCoordinator.configurePiPPreview(
            configProvider: { [pipController] in pipController.config },
            cameraFrameProvider: { [cameraCapture] in cameraCapture.latestFrame },
            pipEnabledProvider: { [pipController] in pipController.isCameraEnabled }
        )
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
