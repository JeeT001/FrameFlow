//
//  ExportViewModel.swift
//  FrameFlow
//

import AVFoundation
import AppKit
import Foundation

@MainActor
@Observable
final class ExportViewModel {
    var recording: RecordingMetadata?
    var selectedResolution: ExportResolution = .p720
    var applyCaptions = true
    var isExporting = false
    var progress: Double = 0
    var statusMessage = ""
    var exportError: String?
    var showSuccessAlert = false
    var exportedURL: URL?

    let player = AVPlayer()

    private var timeObserver: Any?

    var hasCaptionsAvailable: Bool {
        guard let recording else { return false }
        if recording.hasCaptions { return true }
        let url = URL(fileURLWithPath: recording.filePath)
        let segments = (try? CaptionEngine.shared.loadCaptions(for: url, recordingID: recording.id)) ?? []
        return !segments.isEmpty
    }

    var showsCaptionsBadge: Bool {
        hasCaptionsAvailable && applyCaptions
    }

    func load(exportRecordingID: UUID?) {
        guard let exportRecordingID else {
            recording = nil
            return
        }
        recording = RecordingStore.shared.recordings.first { $0.id == exportRecordingID }
        applyCaptions = hasCaptionsAvailable

        if let recording {
            let url = URL(fileURLWithPath: recording.filePath)
            if player.currentItem == nil {
                player.replaceCurrentItem(with: AVPlayerItem(url: url))
            }
            clampResolutionForHardware()
        }
    }

    func canSelectResolution(_ resolution: ExportResolution, isPro: Bool) -> Bool {
        switch resolution {
        case .p720:
            return true
        case .p1080:
            return isPro
        case .p4K:
            return isPro && DeviceCapabilityManager.shared.supports4K
        }
    }

    func lockReason(for resolution: ExportResolution, isPro: Bool) -> String? {
        switch resolution {
        case .p720:
            return nil
        case .p1080:
            return isPro ? nil : "1080p export requires FrameFlow Pro."
        case .p4K:
            if !isPro {
                return "4K export requires FrameFlow Pro."
            }
            if !DeviceCapabilityManager.shared.supports4K {
                return "4K export requires Apple Silicon."
            }
            return nil
        }
    }

    func export(isPro: Bool) async {
        guard let recording else {
            exportError = "No recording selected."
            return
        }

        guard canSelectResolution(selectedResolution, isPro: isPro) else {
            exportError = lockReason(for: selectedResolution, isPro: isPro) ?? "Resolution not available."
            return
        }

        let sourceURL = URL(fileURLWithPath: recording.filePath)
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            exportError = "Recording file was not found on disk."
            return
        }

        isExporting = true
        exportError = nil
        progress = 0
        exportedURL = nil

        defer { isExporting = false }

        let style = ExportService.captionStyle(for: sourceURL, recordingID: recording.id)
        let options = ExportOptions(
            sourceVideoURL: sourceURL,
            recordingID: recording.id,
            resolution: selectedResolution,
            isPro: isPro,
            applyCaptionsIfAvailable: applyCaptions && hasCaptionsAvailable,
            captionStyle: style
        )

        do {
            let url = try await ExportService.shared.export(options: options) { [weak self] value, message in
                Task { @MainActor in
                    self?.progress = value
                    self?.statusMessage = message
                }
            }

            exportedURL = url
            updateRecordingMetadata(afterExport: url, resolution: selectedResolution)
            showSuccessAlert = true
        } catch {
            let rawMessage = error.localizedDescription.lowercased()
            if rawMessage.contains("permission")
                || rawMessage.contains("couldn’t be opened")
                || rawMessage.contains("could not be opened")
                || rawMessage.contains("operation not permitted") {
                exportError = "Re-select your save folder in Settings, then try export again."
            } else {
                exportError = error.localizedDescription
            }
        }
    }

    func revealInFinder() {
        guard let exportedURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([exportedURL])
    }

    func teardown() {
        player.pause()
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        player.replaceCurrentItem(with: nil)
    }

    private func clampResolutionForHardware() {
        if !DeviceCapabilityManager.shared.supports4K, selectedResolution == .p4K {
            selectedResolution = .p1080
        }
    }

    private func updateRecordingMetadata(afterExport url: URL, resolution: ExportResolution) {
        guard var metadata = recording else { return }
        // Keep `filePath` pointing at the original recording; export writes a sibling `_export_*.mp4`.
        _ = url
        _ = resolution
        if applyCaptions && hasCaptionsAvailable {
            metadata.hasCaptions = true
        }

        recording = metadata
        try? RecordingStore.shared.update(metadata)
    }
}
