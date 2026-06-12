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

    /// When set, preview playback and seeks are constrained to this range (Editor trim without middle delete).
    var playbackRange: ClosedRange<Double>?

    /// Export-aware timeline (trim + optional middle delete).
    var editTimeline: EditTimelineModel?

    let player = AVPlayer()

    private var timeObserver: Any?
    private var recordingURL: URL?
    private var recordingID: UUID?
    private var recordingMetadata: RecordingMetadata?

    var activeSegment: CaptionSegment? {
        activeSegmentContext()?.segment
    }

    var overlayDisplayText: String? {
        guard let context = activeSegmentContext() else { return nil }
        let segment = context.segment
        guard WhisperTranscriptSanitizer.speechText(from: segment.text) != nil else { return nil }
        let lookupTime = context.lookupTime
        switch selectedStyle.preset {
        case .tiktokBold:
            return tiktokWord(at: lookupTime, in: segment)
        case .highlightedWord:
            return highlightedPhrase(at: lookupTime, in: segment)
        default:
            return segment.text
        }
    }

    var highlightedWordInOverlay: String? {
        guard selectedStyle.preset == .highlightedWord,
              let context = activeSegmentContext() else { return nil }
        return highlightedWord(at: context.lookupTime, in: context.segment)
    }

    private func activeSegmentContext() -> (segment: CaptionSegment, lookupTime: Double)? {
        if let timeline = editTimeline, !timeline.isFullSourceExport {
            guard let exportTime = CaptionTimelineMapper.exportTime(
                fromSourceTime: currentPlaybackTime,
                editTimeline: timeline
            ) else {
                return nil
            }
            let exportSegments = CaptionTimelineMapper.segmentsForExportTimeline(
                from: segments,
                editTimeline: timeline
            )
            guard let segment = exportSegments.first(where: {
                exportTime >= $0.startTime && exportTime <= $0.endTime
            }) else {
                return nil
            }
            return (segment, exportTime)
        }

        guard let segment = segments.first(where: {
            currentPlaybackTime >= $0.startTime && currentPlaybackTime <= $0.endTime
        }) else {
            return nil
        }
        return (segment, currentPlaybackTime)
    }

    func applyEditTimeline(_ timeline: EditTimelineModel) {
        editTimeline = timeline.isFullSourceExport ? nil : timeline
        if timeline.hasRemovedRegions {
            playbackRange = nil
        } else {
            playbackRange = timeline.trimStartSeconds...timeline.trimEndSeconds
        }
    }

    func sync(from state: CaptionGenerationState) {
        recordingURL = state.videoURL
        recordingID = state.recordingID
        recordingMetadata = state.recordingMetadata

        if !state.segments.isEmpty {
            segments = state.segments
        } else if segments.isEmpty, let url = state.videoURL, let id = state.recordingID {
            segments = (try? SecurityScopedFileAccess.withAccess(to: url) {
                try CaptionEngine.shared.loadCaptions(for: url, recordingID: id)
            }) ?? []
        }

        if let url = state.videoURL, let id = state.recordingID {
            selectedStyle = CaptionEngine.shared.loadStyle(for: url, recordingID: id)
        }

        if let url = state.videoURL, player.currentItem == nil {
            loadPlayer(url: url)
        }
    }

    func loadPreview(url: URL, recording: RecordingMetadata, deferPlayerLoad: Bool = false) {
        recordingURL = url
        recordingID = recording.id
        recordingMetadata = recording
        selectedStyle = CaptionEngine.shared.loadStyle(for: url, recordingID: recording.id)

        if !deferPlayerLoad, player.currentItem == nil {
            loadPlayer(url: url)
        }
    }

    func loadDeferredPlayerIfNeeded() {
        guard player.currentItem == nil, let url = recordingURL else { return }
        loadPlayer(url: url)
    }

    private func loadPlayer(url: URL) {
        Task {
            do {
                try await SecurityScopedFileAccess.withAccess(to: url) {
                    configurePlayer(url: url)
                }
            } catch SecurityScopedFileAccess.AccessError.denied {
                exportError = SecurityScopedFileAccess.accessDeniedMessage
            } catch {
                exportError = error.localizedDescription
            }
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
        selectedStyle.customVerticalOffsetNormalized = nil
    }

    func updateCaptionVerticalOffset(_ offset: Double) {
        selectedStyle.customVerticalOffsetNormalized = min(
            max(offset, CaptionStyleConfig.verticalOffsetRange.lowerBound),
            CaptionStyleConfig.verticalOffsetRange.upperBound
        )
    }

    func updateSegmentTimes(id: UUID, start: Double?, end: Double?) {
        guard let index = segments.firstIndex(where: { $0.id == id }) else { return }

        var newStart = start ?? segments[index].startTime
        var newEnd = end ?? segments[index].endTime

        if let range = playbackRange {
            newStart = max(newStart, range.lowerBound)
            newEnd = min(newEnd, range.upperBound)
        }

        let maxDuration = max(videoDuration, 0.1)
        newStart = max(0, min(newStart, maxDuration - 0.1))
        newEnd = max(newStart + 0.1, min(newEnd, maxDuration))

        guard newEnd - newStart >= 0.1 else { return }

        segments[index].startTime = newStart
        segments[index].endTime = newEnd
        segments.sort { $0.startTime < $1.startTime }
        CaptionGenerationState.shared.applySegments(segments)
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
        var clamped = max(0, min(time, max(videoDuration, 0.1)))
        if let timeline = editTimeline {
            clamped = CaptionTimelineMapper.snapToKeptSourceTime(clamped, editTimeline: timeline)
        } else if let range = playbackRange {
            clamped = min(max(clamped, range.lowerBound), range.upperBound)
        }
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
            if let timeline = editTimeline, !timeline.isFullSourceExport {
                let firstStart = timeline.keptSourceRanges.first?.start ?? timeline.trimStartSeconds
                let lastEnd = timeline.keptSourceRanges.last?.end ?? timeline.trimEndSeconds
                if currentPlaybackTime >= lastEnd - 0.05
                    || CaptionTimelineMapper.exportTime(fromSourceTime: currentPlaybackTime, editTimeline: timeline) == nil {
                    seek(to: firstStart)
                }
            } else {
                let rangeEnd = playbackRange?.upperBound ?? videoDuration
                let rangeStart = playbackRange?.lowerBound ?? 0
                if currentPlaybackTime >= rangeEnd - 0.05 {
                    seek(to: rangeStart)
                }
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
            try await SecurityScopedFileAccess.withAccess(to: videoURL) {
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
            }

            showExportSuccessAlert = true
        } catch SecurityScopedFileAccess.AccessError.denied {
            exportError = SecurityScopedFileAccess.accessDeniedMessage
        } catch {
            exportError = error.localizedDescription
        }
    }

    func revealExportedFiles() {
        for url in exportedPaths {
            do {
                try SecurityScopedFileAccess.withAccess(to: url) {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            } catch SecurityScopedFileAccess.AccessError.denied {
                exportError = SecurityScopedFileAccess.accessDeniedMessage
                return
            } catch {
                exportError = error.localizedDescription
                return
            }
        }
    }

    func teardown() {
        player.pause()
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        player.replaceCurrentItem(with: nil)
        playbackRange = nil
        editTimeline = nil
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
                var seconds = CMTimeGetSeconds(time)

                if let timeline = self.editTimeline, timeline.hasRemovedRegions {
                    seconds = self.enforceRemovedRegionsPlayback(at: seconds, timeline: timeline)
                } else if let range = self.playbackRange {
                    if seconds >= range.upperBound {
                        self.player.pause()
                        seconds = range.upperBound
                    } else if seconds < range.lowerBound {
                        seconds = range.lowerBound
                    }
                }

                self.currentPlaybackTime = seconds
            }
        }
    }

    private func enforceRemovedRegionsPlayback(at seconds: Double, timeline: EditTimelineModel) -> Double {
        for removed in timeline.sortedRemovedRanges {
            if seconds >= removed.startSeconds, seconds < removed.endSeconds - 0.02 {
                let jumpTo = removed.endSeconds
                player.seek(
                    to: CMTime(seconds: jumpTo, preferredTimescale: 600),
                    toleranceBefore: .zero,
                    toleranceAfter: .zero
                )
                return jumpTo
            }
        }

        if let last = timeline.keptSourceRanges.last, seconds >= last.end - 0.05 {
            player.pause()
            return last.end
        }

        for (index, range) in timeline.keptSourceRanges.enumerated() {
            if seconds >= range.start, seconds < range.end {
                return seconds
            }
            if index + 1 < timeline.keptSourceRanges.count {
                let next = timeline.keptSourceRanges[index + 1]
                if seconds >= range.end, seconds < next.start {
                    player.seek(
                        to: CMTime(seconds: next.start, preferredTimescale: 600),
                        toleranceBefore: .zero,
                        toleranceAfter: .zero
                    )
                    return next.start
                }
            }
        }

        if let first = timeline.keptSourceRanges.first, seconds < first.start {
            return first.start
        }

        return seconds
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
