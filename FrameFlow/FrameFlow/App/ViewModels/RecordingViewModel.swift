//
//  RecordingViewModel.swift
//  FrameFlow
//

import CoreGraphics
import Foundation

enum RecordingScreenPhase: Equatable {
    case countdown
    case recording
    case idle
}

@MainActor
@Observable
final class RecordingViewModel {
    let coordinator = RecordingSessionCoordinator()

    private(set) var phase: RecordingScreenPhase = .idle
    private(set) var countdownValue: Int?
    private(set) var isStopping = false
    private(set) var isHUDVisible = true

    private var hudAutoHideTask: Task<Void, Never>?

    var isPaused: Bool {
        coordinator.engine.isPaused
    }

    var zoomLabel: String {
        String(format: "%.1fx", coordinator.displayZoomScale)
    }

    var audioMode: AudioModeOption {
        AudioModeOption(rawValue: SettingsStore.shared.defaultAudioMode) ?? .none
    }

    func runRecordingFlow(appState: AppState) async {
        guard !appState.selectedWindowIDs.isEmpty else {
            coordinator.errorMessage = "No windows selected. Return to the Window Picker."
            phase = .idle
            return
        }

        phase = .idle
        await runCountdownIfNeeded()

        guard !Task.isCancelled else { return }

        phase = .recording
        await startIfPossible(appState: appState)

        guard coordinator.isRecording else {
            phase = .idle
            return
        }

        revealHUD(andScheduleAutoHide: !isPaused)
    }

    func startIfPossible(appState: AppState) async {
        guard !appState.selectedWindowIDs.isEmpty else {
            coordinator.errorMessage = "No windows selected. Return to the Window Picker."
            return
        }

        let tempURL = makeTempOutputURL()
        await coordinator.startRecording(
            windowIDs: appState.selectedWindowIDs,
            format: appState.selectedFormat,
            preset: appState.selectedLayoutPreset,
            outputURL: tempURL,
            isPro: appState.isPro
        )
    }

    func stopAndStage(appState: AppState) async throws -> RecordingMetadata {
        guard !isStopping else { throw RecordingEngineError.notRecording }
        isStopping = true
        defer { isStopping = false }

        hudAutoHideTask?.cancel()
        isHUDVisible = true

        let durationSeconds = coordinator.engine.currentDurationSeconds()
        let recordingID = UUID()
        try RecordingStaging.ensureDirectoryExists()
        let stagingURL = RecordingStaging.fileURL(recordingID: recordingID)
        let stagedURL = try await coordinator.finalizeAndStop(moveTo: stagingURL)
        let resolutionString = resolutionString(for: appState.selectedFormat)
        let fileSize = (try? fileSizeBytes(at: stagedURL)) ?? 0

        phase = .idle

        return RecordingMetadata(
            id: recordingID,
            name: defaultRecordingName(),
            filePath: stagedURL.path,
            durationSeconds: durationSeconds,
            resolution: resolutionString,
            format: appState.selectedFormat.rawValue,
            layout: appState.selectedLayoutPreset.rawValue,
            windowCount: appState.selectedWindowIDs.count,
            hasCaptions: false,
            hasCamera: PiPController.shared.isCameraEnabled,
            audioMode: SettingsStore.shared.defaultAudioMode,
            createdAt: Date(),
            fileSizeBytes: fileSize
        )
    }

    func stopWithoutSaving() async {
        hudAutoHideTask?.cancel()
        phase = .idle
        countdownValue = nil
        await coordinator.stopAll()
    }

    func togglePauseResume() {
        guard coordinator.isRecording else { return }
        if coordinator.engine.isPaused {
            coordinator.resumeRecording()
            revealHUD(andScheduleAutoHide: true)
        } else {
            coordinator.pauseRecording()
            hudAutoHideTask?.cancel()
            isHUDVisible = true
        }
    }

    func previewInteraction() {
        guard phase == .recording, coordinator.isRecording else { return }
        revealHUD(andScheduleAutoHide: !isPaused)
    }

    var onStopRecording: (() -> Void)?
    var onDiscardRecording: (() -> Void)?
    var onPiPUpgradeRequired: (() -> Void)?
    var isPro = false

    private func runCountdownIfNeeded() async {
        let seconds = max(0, SettingsStore.shared.countdownDuration)
        guard seconds > 0 else { return }

        phase = .countdown
        for value in stride(from: seconds, through: 1, by: -1) {
            guard !Task.isCancelled else {
                countdownValue = nil
                phase = .idle
                return
            }
            countdownValue = value
            try? await Task.sleep(for: .seconds(1))
        }
        countdownValue = nil
    }

    private func revealHUD(andScheduleAutoHide schedule: Bool) {
        isHUDVisible = true
        hudAutoHideTask?.cancel()
        guard schedule else { return }

        hudAutoHideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            if phase == .recording, coordinator.isRecording, !coordinator.engine.isPaused {
                isHUDVisible = false
            }
        }
    }

    private func makeTempOutputURL() -> URL {
        let name = "FrameFlow_temp_\(UUID().uuidString).mp4"
        return FileManager.default.temporaryDirectory.appendingPathComponent(name)
    }

    private func fileSizeBytes(at url: URL) throws -> Int {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int ?? 0
    }

    private func defaultRecordingName() -> String {
        "Recording \(timestampForDisplay())"
    }

    private func timestampForDisplay() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    private func resolutionString(for format: RecordingFormat) -> String {
        let base = SettingsStore.shared.defaultResolution.lowercased()

        let landscape: (Int, Int)
        switch base {
        case "4k":
            landscape = DeviceCapabilityManager.shared.supports4K ? (3840, 2160) : (1920, 1080)
        case "720p":
            landscape = (1280, 720)
        default:
            landscape = (1920, 1080)
        }

        if format == .sixteenByNine {
            return "\(landscape.0)x\(landscape.1)"
        } else {
            return "\(landscape.1)x\(landscape.0)"
        }
    }
}

extension RecordingViewModel: RecordingKeyboardShortcutHandling {
    func shortcutTogglePauseResume() {
        togglePauseResume()
    }

    func shortcutStopRecording() {
        guard phase == .recording, coordinator.isRecording, !isStopping else { return }
        onStopRecording?()
    }

    func shortcutZoomIn() {
        guard coordinator.isRecording else { return }
        coordinator.zoomIn()
        previewInteraction()
    }

    func shortcutZoomOut() {
        guard coordinator.isRecording else { return }
        coordinator.zoomOut()
        previewInteraction()
    }

    func shortcutResetZoom() {
        guard coordinator.isRecording else { return }
        coordinator.resetZoom()
        previewInteraction()
    }

    func shortcutToggleAutoFocus() {
        guard coordinator.isRecording else { return }
        coordinator.toggleAutoFocus()
        previewInteraction()
    }

    func shortcutToggleCursorHighlight() {
        guard coordinator.isRecording else { return }
        coordinator.toggleCursorHighlight()
        previewInteraction()
    }

    func shortcutTogglePiPCamera() {
        guard coordinator.isRecording else { return }
        Task {
            let toggled = await coordinator.togglePiPCamera(isPro: isPro)
            if !toggled {
                onPiPUpgradeRequired?()
            } else {
                previewInteraction()
            }
        }
    }

    func shortcutDiscardRecording() {
        guard coordinator.isRecording || phase == .recording else { return }
        onDiscardRecording?()
    }
}
