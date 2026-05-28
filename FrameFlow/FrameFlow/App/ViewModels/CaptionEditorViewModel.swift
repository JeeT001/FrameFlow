//
//  CaptionEditorViewModel.swift
//  FrameFlow
//

import AppKit
import AVFoundation
import Foundation

@MainActor
@Observable
final class CaptionEditorViewModel {
    enum CaptionExportFormat: String, CaseIterable, Identifiable {
        case burnedIn = "Burned In"
        case srt = "SRT File"
        case both = "Both"

        var id: String { rawValue }
    }

    var segments: [CaptionSegment] = []
    var selectedStyle: CaptionStyleConfig = .fromSettings()
    var exportFormat: CaptionExportFormat = .both
    var currentPlaybackTime: Double = 0
    var videoDuration: Double = 1
    var selectedSegmentID: UUID?
    var isExporting = false
    var exportProgress: Double = 0
    var exportStatusMessage = ""
    var exportError: String?
    var showExportSuccessAlert = false
    var exportedPaths: [URL] = []

    let player = AVPlayer()

    private var timeObserver: Any?
    private var recordingURL: URL?
    private var recordingID: UUID?
    private var recordingMetadata: RecordingMetadata?

    var activeSegment: CaptionSegment? {
        segments.first { currentPlaybackTime >= $0.startTime && currentPlaybackTime <= $0.endTime }
    }

    var overlayDisplayText: String? {
        guard let segment = activeSegment else { return nil }
        switch selectedStyle.preset {
        case .tiktokBold:
            return tiktokWord(at: currentPlaybackTime, in: segment)
        case .highlightedWord:
            return highlightedPhrase(at: currentPlaybackTime, in: segment)
        default:
            return segment.text
        }
    }

    var highlightedWordInOverlay: String? {
        guard selectedStyle.preset == .highlightedWord, let segment = activeSegment else { return nil }
        return highlightedWord(at: currentPlaybackTime, in: segment)
    }

    func sync(from state: CaptionGenerationState) {
        recordingURL = state.videoURL
        recordingID = state.recordingID
        recordingMetadata = state.recordingMetadata

        if !state.segments.isEmpty {
            segments = state.segments
        } else if segments.isEmpty, let url = state.videoURL, let id = state.recordingID {
            segments = (try? CaptionEngine.shared.loadCaptions(for: url, recordingID: id)) ?? []
        }

        if let url = state.videoURL, player.currentItem == nil {
            configurePlayer(url: url)
        }
    }

    func selectStyle(_ preset: CaptionStylePreset) {
        selectedStyle = CaptionStyleConfig.config(
            for: preset,
            position: selectedStyle.verticalPosition
        )
    }

    func setPosition(_ position: CaptionVerticalPosition) {
        selectedStyle.verticalPosition = position
    }

    func updateSegmentText(id: UUID, text: String) {
        guard let index = segments.firstIndex(where: { $0.id == id }) else { return }
        segments[index].text = text
        CaptionGenerationState.shared.applySegments(segments)
    }

    func selectSegment(_ segment: CaptionSegment) {
        selectedSegmentID = segment.id
        seek(to: segment.startTime)
    }

    func seek(to time: Double) {
        let clamped = max(0, min(time, max(videoDuration, 0.1)))
        currentPlaybackTime = clamped
        player.seek(
            to: CMTime(seconds: clamped, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
        selectedSegmentID = segments.first {
            clamped >= $0.startTime && clamped <= $0.endTime
        }?.id
    }

    func togglePlayback() {
        if player.rate > 0 {
            player.pause()
        } else {
            if currentPlaybackTime >= videoDuration - 0.05 {
                seek(to: 0)
            }
            player.play()
        }
    }

    func exportCaptions() async {
        guard let videoURL = recordingURL, let recordingID = recordingID else {
            exportError = "Recording file is unavailable."
            return
        }

        isExporting = true
        exportError = nil
        exportProgress = 0
        exportedPaths = []
        exportStatusMessage = "Saving captions…"

        defer { isExporting = false }

        do {
            try CaptionEngine.shared.saveCaptions(
                segments,
                for: videoURL,
                recordingID: recordingID,
                style: selectedStyle
            )
            exportProgress = 0.15

            let engine = CaptionEngine.shared
            let srtURL = engine.srtURL(for: videoURL)
            let burnedURL = engine.burnedInURL(for: videoURL)
            var paths: [URL] = []

            switch exportFormat {
            case .srt:
                try CaptionRenderer.shared.writeSRT(segments: segments, to: srtURL)
                paths = [srtURL]
                exportProgress = 1
            case .burnedIn:
                exportStatusMessage = "Rendering captions into video…"
                exportProgress = 0.35
                try await CaptionRenderer.shared.burnInCaptions(
                    videoURL: videoURL,
                    segments: segments,
                    style: selectedStyle,
                    outputURL: burnedURL
                )
                paths = [burnedURL]
                exportProgress = 1
            case .both:
                try CaptionRenderer.shared.writeSRT(segments: segments, to: srtURL)
                exportProgress = 0.35
                exportStatusMessage = "Rendering captions into video…"
                try await CaptionRenderer.shared.burnInCaptions(
                    videoURL: videoURL,
                    segments: segments,
                    style: selectedStyle,
                    outputURL: burnedURL
                )
                paths = [srtURL, burnedURL]
                exportProgress = 1
            }

            exportedPaths = paths
            exportStatusMessage = "Export complete."

            if var metadata = recordingMetadata {
                metadata.hasCaptions = true
                recordingMetadata = metadata
                try? RecordingStore.shared.update(metadata)
                CaptionGenerationState.shared.recordingMetadata = metadata
            }

            let captionState = CaptionGenerationState.shared
            captionState.applySegments(segments)
            if exportFormat != .burnedIn {
                captionState.srtURL = srtURL
            }
            if exportFormat != .srt {
                captionState.burnedInVideoURL = burnedURL
            }

            showExportSuccessAlert = true
        } catch {
            exportError = error.localizedDescription
        }
    }

    func revealExportedFiles() {
        for url in exportedPaths {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    func teardown() {
        player.pause()
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        player.replaceCurrentItem(with: nil)
    }

    private func configurePlayer(url: URL) {
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)

        Task {
            let asset = AVURLAsset(url: url)
            let duration = try? await asset.load(.duration)
            let seconds = duration.map { CMTimeGetSeconds($0) } ?? 1
            videoDuration = max(seconds, 0.1)
        }

        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }

        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentPlaybackTime = CMTimeGetSeconds(time)
            }
        }
    }

    private func tiktokWord(at time: Double, in segment: CaptionSegment) -> String {
        let words = segment.text.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return segment.text }
        let duration = max(0.05, segment.endTime - segment.startTime)
        let progress = max(0, min(1, (time - segment.startTime) / duration))
        let index = min(words.count - 1, Int(progress * Double(words.count)))
        return words[index].uppercased()
    }

    private func highlightedWord(at time: Double, in segment: CaptionSegment) -> String? {
        let words = segment.text.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return nil }
        let duration = max(0.05, segment.endTime - segment.startTime)
        let progress = max(0, min(1, (time - segment.startTime) / duration))
        let index = min(words.count - 1, Int(progress * Double(words.count)))
        return words[index]
    }

    private func highlightedPhrase(at time: Double, in segment: CaptionSegment) -> String {
        segment.text
    }
}
