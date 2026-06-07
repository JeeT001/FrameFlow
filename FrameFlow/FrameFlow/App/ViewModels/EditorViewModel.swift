//
//  EditorViewModel.swift
//  FrameFlow
//

import Foundation

enum EditorTab: String, CaseIterable, Identifiable {
    case edit = "Edit"
    case captions = "Captions"
    case export = "Export"

    var id: String { rawValue }
}

@MainActor
@Observable
final class EditorViewModel {
    var selectedTab: EditorTab = .edit

    var sourceDurationSeconds: Double = 1
    var trimStartSeconds: Double = 0
    var trimEndSeconds: Double = 1

    let captionViewModel = CaptionEditorViewModel()
    let exportViewModel = ExportViewModel()

    var trimDurationSeconds: Double {
        max(0, trimEndSeconds - trimStartSeconds)
    }

    var hasTrimApplied: Bool {
        trimStartSeconds > 0.001 || trimEndSeconds < sourceDurationSeconds - 0.001
    }

    var formattedTrimDuration: String {
        TrimHelpers.formatDurationClock(trimDurationSeconds)
    }

    static func tabs(isPro: Bool) -> [EditorTab] {
        isPro ? EditorTab.allCases : [.edit, .export]
    }

    func load(appState: AppState, isPro: Bool) {
        exportViewModel.load(
            exportRecordingID: appState.exportRecordingID,
            pendingRecording: appState.pendingRecording,
            isPro: isPro
        )
        exportViewModel.trimStartSeconds = nil
        exportViewModel.trimEndSeconds = nil

        guard let recording = exportViewModel.recording else { return }

        let url = URL(fileURLWithPath: recording.filePath)
        captionViewModel.loadPreview(url: url, recording: recording)
        configureTrim(from: captionViewModel.videoDuration)

        if isPro {
            captionViewModel.sync(from: CaptionGenerationState.shared)
        }
    }

    func onVideoDurationLoaded(_ duration: Double) {
        configureTrim(from: duration)
    }

    func configureTrim(from duration: Double) {
        sourceDurationSeconds = max(duration, TrimHelpers.minimumSpanSeconds)
        trimStartSeconds = 0
        trimEndSeconds = sourceDurationSeconds
        syncPlaybackRange()
    }

    func updateTrimStart(_ value: Double) {
        trimStartSeconds = value
        clampTrimHandles()
        syncPlaybackRange()
        clampPlaybackToTrim()
    }

    func updateTrimEnd(_ value: Double) {
        trimEndSeconds = value
        clampTrimHandles()
        syncPlaybackRange()
        clampPlaybackToTrim()
    }

    func clampTrimHandles() {
        let minSpan = TrimHelpers.minimumSpanSeconds
        trimStartSeconds = max(0, min(trimStartSeconds, sourceDurationSeconds - minSpan))
        trimEndSeconds = min(sourceDurationSeconds, max(trimEndSeconds, trimStartSeconds + minSpan))
    }

    func segmentsForExport(from segments: [CaptionSegment]) -> [CaptionSegment] {
        guard hasTrimApplied else { return segments }
        return TrimHelpers.segmentsForExport(
            from: segments,
            trimStart: trimStartSeconds,
            trimEnd: trimEndSeconds,
            relativeToTrimStart: false
        )
    }

    func exportRecording(isPro: Bool, appState: AppState) async {
        if isPro, !captionViewModel.segments.isEmpty {
            do {
                try await saveCaptionsBeforeExport()
            } catch SecurityScopedFileAccess.AccessError.denied {
                exportViewModel.exportError = SecurityScopedFileAccess.accessDeniedMessage
                return
            } catch {
                exportViewModel.exportError = error.localizedDescription
                return
            }
        }

        if hasTrimApplied {
            exportViewModel.trimStartSeconds = trimStartSeconds
            exportViewModel.trimEndSeconds = trimEndSeconds
        } else {
            exportViewModel.trimStartSeconds = nil
            exportViewModel.trimEndSeconds = nil
        }

        await exportViewModel.export(isPro: isPro, appState: appState)

        guard exportViewModel.exportedURL != nil, exportViewModel.exportError == nil else { return }

        if isPro, exportViewModel.alsoSaveSRT, exportViewModel.hasCaptionsAvailable {
            await writeExportSRT(isPro: isPro)
        }
    }

    func discard(appState: AppState) {
        exportViewModel.discardPending(appState: appState)
        CaptionGenerationState.shared.reset()
        teardown()
    }

    func teardown() {
        captionViewModel.playbackRange = nil
        captionViewModel.teardown()
        exportViewModel.teardown()
    }

    private func syncPlaybackRange() {
        captionViewModel.playbackRange = trimStartSeconds...trimEndSeconds
    }

    private func clampPlaybackToTrim() {
        let time = captionViewModel.currentPlaybackTime
        if time < trimStartSeconds || time > trimEndSeconds {
            captionViewModel.seek(to: trimStartSeconds)
        }
    }

    private func saveCaptionsBeforeExport() async throws {
        guard let recording = exportViewModel.recording else { return }
        let url = URL(fileURLWithPath: recording.filePath)
        try await SecurityScopedFileAccess.withAccess(to: url) {
            try CaptionEngine.shared.saveCaptions(
                captionViewModel.segments,
                for: url,
                recordingID: recording.id,
                style: captionViewModel.selectedStyle
            )
        }
    }

    private func writeExportSRT(isPro: Bool) async {
        guard isPro,
              let exportedURL = exportViewModel.exportedURL else { return }

        var segments = captionViewModel.segments
        if hasTrimApplied {
            segments = TrimHelpers.segmentsForExport(
                from: segments,
                trimStart: trimStartSeconds,
                trimEnd: trimEndSeconds,
                relativeToTrimStart: true
            )
        }
        guard !segments.isEmpty else { return }

        let srtURL = exportedURL.deletingPathExtension().appendingPathExtension("srt")
        do {
            try await SecurityScopedFileAccess.withAccess(to: exportedURL) {
                try CaptionRenderer.shared.writeSRT(segments: segments, to: srtURL)
            }
        } catch {
            exportViewModel.exportError = "MP4 exported but SRT save failed: \(error.localizedDescription)"
        }
    }
}
