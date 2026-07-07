//
//  ExportViewModel.swift
//  FrameFlow
//

import AVFoundation
import AppKit
import Foundation
import os.log

enum ExportCaptionSource: String {
    case memory
    case staged
    case generationState
    case sidecar
    case none
}

@MainActor
@Observable
final class ExportViewModel {
    var recording: RecordingMetadata?
    var isPendingExport = false
    var selectedResolution: ExportResolution = .p720
    var applyCaptions = true
    var isExporting = false
    var progress: Double = 0
    var statusMessage = ""
    var exportError: String?
    var showSuccessAlert = false
    var exportedURL: URL?
    var trimStartSeconds: Double?
    var trimEndSeconds: Double?
    var alsoSaveSRT = false
    var editTimeline: EditTimelineModel?
    var editorProject: EditorProjectModel?
    var exportDurationOverride: Double?

    var isExportSheetPresented = false

    /// Segments from the editor preview — preferred caption source for export.
    var captionSegmentsForExport: [CaptionSegment] = []
    /// Editor caption style — preferred over sidecar when set before export.
    var captionStyleForExport: CaptionStyleConfig?
    /// Matches `CaptionEditorViewModel.videoContentStartSeconds` for timeline parity with preview.
    var editorLeadingGapForExport: Double = 0

    let player = AVPlayer()

    private static let log = Logger(subsystem: "com.Simranjit.FrameFlow", category: "ExportViewModel")
    private var timeObserver: Any?
    private(set) var lastCaptionSource: ExportCaptionSource = .none

    var hasCaptionsAvailable: Bool {
        guard recording != nil else { return false }
        if !captionSegmentsForExport.isEmpty {
            return true
        }
        return !resolvedCaptionSegments().isEmpty
    }

    /// Editor path: captions often exist only in memory until export. Sync before showing the sheet.
    func prepareEditorExport(segments: [CaptionSegment], leadingGap: Double) {
        captionSegmentsForExport = segments
        editorLeadingGapForExport = leadingGap
        if !segments.isEmpty {
            applyCaptions = true
        }
    }

    var showsCaptionsBadge: Bool {
        hasCaptionsAvailable && applyCaptions
    }

    var shouldShowExportWithoutCaptionsWarning: Bool {
        hasCaptionsAvailable
            && !applyCaptions
            && !isExporting
            && !SettingsStore.shared.exportWithoutCaptionsWarningShown
    }

    func markExportWithoutCaptionsWarningShown() {
        SettingsStore.shared.exportWithoutCaptionsWarningShown = true
    }

    func load(
        exportRecordingID: UUID?,
        pendingRecording: RecordingMetadata?,
        isPro: Bool,
        appState: AppState? = nil
    ) {
        guard let exportRecordingID else {
            recording = nil
            isPendingExport = false
            return
        }

        if let pending = pendingRecording, pending.id == exportRecordingID {
            recording = pending
            isPendingExport = true
        } else {
            recording = RecordingStore.shared.recordings.first { $0.id == exportRecordingID }
            isPendingExport = false
        }

        trimStartSeconds = nil
        trimEndSeconds = nil
        alsoSaveSRT = false
        editTimeline = nil
        editorProject = nil
        exportDurationOverride = nil
        isExportSheetPresented = false

        syncCaptionSources(
            recordingID: exportRecordingID,
            appState: appState
        )
        applyCaptions = hasCaptionsAvailable

        if let recording {
            let url = URL(fileURLWithPath: recording.filePath)
            Task {
                do {
                    try await SecurityScopedFileAccess.withAccess(to: url) {
                        player.replaceCurrentItem(with: AVPlayerItem(url: url))
                    }
                } catch SecurityScopedFileAccess.AccessError.denied {
                    exportError = SecurityScopedFileAccess.accessDeniedMessage
                    player.replaceCurrentItem(with: nil)
                } catch {
                    exportError = error.localizedDescription
                    player.replaceCurrentItem(with: nil)
                }
            }
            applyDefaultResolution(isPro: isPro)
        } else {
            player.replaceCurrentItem(with: nil)
        }
    }

    func applyDefaultResolution(isPro: Bool) {
        let pref = SettingsStore.shared.defaultResolution.lowercased()
        let requested: ExportResolution
        switch pref {
        case "4k":
            requested = .p4K
        case "720p":
            requested = .p720
        default:
            requested = .p1080
        }

        if canSelectResolution(requested, isPro: isPro) {
            selectedResolution = requested
        } else if requested == .p4K, canSelectResolution(.p1080, isPro: isPro) {
            selectedResolution = .p1080
        } else {
            selectedResolution = .p720
        }

        clampResolutionForHardware()
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
            return isPro ? nil : "1080p export requires \(AppBranding.proName)."
        case .p4K:
            if !isPro {
                return "4K export requires \(AppBranding.proName)."
            }
            if !DeviceCapabilityManager.shared.supports4K {
                return "4K export requires Apple Silicon."
            }
            return nil
        }
    }

    func export(isPro: Bool, appState: AppState, exportPath: String = "exportView") async {
        guard let recording else {
            exportError = "No recording selected."
            return
        }

        if captionSegmentsForExport.isEmpty {
            syncCaptionSources(recordingID: recording.id, appState: appState)
        } else {
            lastCaptionSource = .memory
        }
        await resolveLeadingGapIfNeeded(for: recording)

        guard canSelectResolution(selectedResolution, isPro: isPro) else {
            exportError = lockReason(for: selectedResolution, isPro: isPro) ?? "Resolution not available."
            return
        }

        if applyCaptions {
            let segments = resolvedCaptionSegments()
            if segments.isEmpty {
                exportError = ExportServiceError.captionsRequiredButUnavailable.errorDescription
                return
            }
        }

        let sourceURL = URL(fileURLWithPath: recording.filePath)
        guard SecurityScopedFileAccess.canAccess(sourceURL) else {
            exportError = SecurityScopedFileAccess.accessDeniedMessage
            return
        }

        isExporting = true
        exportError = nil
        progress = 0
        exportedURL = nil

        defer { isExporting = false }

        let previousPath = recording.filePath
        let style = captionStyleForExport ?? (try? SecurityScopedFileAccess.withAccess(to: sourceURL) {
            ExportService.captionStyle(for: sourceURL, recordingID: recording.id)
        }) ?? CaptionStyleConfig.fromSettings()
        let outputFilename = Self.exportFilename(
            for: recording,
            resolution: selectedResolution,
            isFirstExport: isPendingExport
        )
        let preparedProject = editorProject?.preparedForExport()
            ?? editTimeline.map { EditorProjectModel(timeline: $0.preparedForExport()) }?.preparedForExport()
        let exportSegments = applyCaptions ? resolvedCaptionSegments() : []
        Self.log.info(
            "export path=\(exportPath, privacy: .public) applyCaptions=\(self.applyCaptions) segments=\(exportSegments.count) source=\(self.lastCaptionSource.rawValue, privacy: .public) leadingGap=\(self.editorLeadingGapForExport, format: .fixed(precision: 3))"
        )
        let options = ExportOptions(
            sourceVideoURL: sourceURL,
            recordingID: recording.id,
            resolution: selectedResolution,
            isPro: isPro,
            applyCaptionsIfAvailable: applyCaptions && !exportSegments.isEmpty,
            captionStyle: style,
            outputFilename: outputFilename,
            editTimeline: preparedProject?.timeline,
            editorProject: preparedProject,
            leadingVideoGapSeconds: recording.captionAudioLeadSeconds,
            editorLeadingVideoGapSeconds: editorLeadingGapForExport,
            captionSegments: applyCaptions ? exportSegments : nil,
            skipLeadingGapTrim: false
        )

        do {
            let url = try await ExportService.shared.export(options: options) { [weak self] value, message in
                Task { @MainActor in
                    self?.progress = value
                    self?.statusMessage = message
                }
            }

            exportedURL = url
            try persistAfterExport(
                exportedURL: url,
                previousPath: previousPath,
                appState: appState,
                captionStyle: style
            )
            if let exported = self.recording {
                AnalyticsService.trackExportCompleted(
                    resolution: selectedResolution.rawValue,
                    hasCaptions: exported.hasCaptions,
                    hasCamera: exported.hasCamera
                )
            }
            SettingsStore.shared.recordSuccessfulExport()
            showSuccessAlert = true
        } catch SecurityScopedFileAccess.AccessError.denied {
            exportError = SecurityScopedFileAccess.accessDeniedMessage
        } catch {
            if ExportDiskSpaceChecker.isDiskFullError(error) {
                exportError = ExportDiskSpaceChecker.diskFullMessage
            } else {
                let rawMessage = error.localizedDescription.lowercased()
                if rawMessage.contains("permission")
                    || rawMessage.contains("couldn’t be opened")
                    || rawMessage.contains("could not be opened")
                    || rawMessage.contains("operation not permitted") {
                    exportError = "Re-select your save folder in Settings, then try export again."
                } else {
                    exportError = ExportDiskSpaceChecker.userFacingExportError(error)
                }
            }
        }
    }

    func discardPending(appState: AppState) {
        if let pending = appState.pendingRecording {
            RecordingFileCleanup.deleteStagingAndSidecars(for: pending)
        }
        appState.pendingRecording = nil
        appState.exportRecordingID = nil
    }

    func revealInFinder() {
        guard let exportedURL else { return }
        do {
            try SecurityScopedFileAccess.withAccess(to: exportedURL) {
                NSWorkspace.shared.activateFileViewerSelecting([exportedURL])
            }
        } catch SecurityScopedFileAccess.AccessError.denied {
            exportError = SecurityScopedFileAccess.accessDeniedMessage
        } catch {
            exportError = error.localizedDescription
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

    private func clampResolutionForHardware() {
        if !DeviceCapabilityManager.shared.supports4K, selectedResolution == .p4K {
            selectedResolution = .p1080
        }
    }

    private func persistAfterExport(
        exportedURL: URL,
        previousPath: String,
        appState: AppState,
        captionStyle: CaptionStyleConfig
    ) throws {
        guard var metadata = recording else { return }

        let segmentsToPersist = applyCaptions ? resolvedCaptionSegments() : []

        if isPendingExport {
            RecordingFileCleanup.deleteStagingAndSidecars(for: metadata)
        }

        let attributes = try? FileManager.default.attributesOfItem(atPath: exportedURL.path)
        metadata.filePath = exportedURL.path
        metadata.fileSizeBytes = attributes?[.size] as? Int ?? metadata.fileSizeBytes
        metadata.resolution = resolutionBadge(for: selectedResolution, format: metadata.format)
        if applyCaptions, !segmentsToPersist.isEmpty {
            metadata.hasCaptions = true
            try SecurityScopedFileAccess.withAccess(to: exportedURL) {
                try CaptionEngine.shared.saveCaptions(
                    segmentsToPersist,
                    for: exportedURL,
                    recordingID: metadata.id,
                    style: captionStyle,
                    audioLeadSeconds: metadata.captionAudioLeadSeconds > 0.001
                        ? metadata.captionAudioLeadSeconds
                        : nil
                )
            }
        }
        if let exportDuration = exportDurationOverride, exportDuration > 0 {
            metadata.durationSeconds = max(1, Int(exportDuration.rounded(.toNearestOrAwayFromZero)))
        } else if let timeline = editTimeline, timeline.requiresStitchExport {
            metadata.durationSeconds = max(1, Int(timeline.exportDurationSeconds.rounded(.toNearestOrAwayFromZero)))
        } else if let trimStart = trimStartSeconds,
           let trimEnd = trimEndSeconds,
           trimEnd > trimStart {
            metadata.durationSeconds = max(1, Int((trimEnd - trimStart).rounded()))
        }

        if isPendingExport {
            try RecordingStore.shared.add(metadata)
            appState.pendingRecording = nil
            isPendingExport = false
        } else {
            if previousPath != exportedURL.path,
               FileManager.default.fileExists(atPath: previousPath) {
                try? FileManager.default.removeItem(atPath: previousPath)
            }
            try RecordingStore.shared.update(metadata)
        }

        recording = metadata
    }

    private static func exportFilename(
        for recording: RecordingMetadata,
        resolution: ExportResolution,
        isFirstExport: Bool
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let stamp = formatter.string(from: isFirstExport ? recording.createdAt : Date())
        return "\(AppBranding.name)_\(stamp)_\(resolution.rawValue).mp4"
    }

    private func resolutionBadge(for resolution: ExportResolution, format: String) -> String {
        let landscape: String
        switch resolution {
        case .p720: landscape = "1280x720"
        case .p1080: landscape = "1920x1080"
        case .p4K: landscape = "3840x2160"
        }
        if format == "9:16" {
            let parts = landscape.split(separator: "x")
            if parts.count == 2 {
                return "\(parts[1])x\(parts[0])"
            }
        }
        return landscape
    }

    func resolvedCaptionSegments() -> [CaptionSegment] {
        if !captionSegmentsForExport.isEmpty {
            lastCaptionSource = .memory
            return captionSegmentsForExport
        }
        guard let recording else {
            lastCaptionSource = .none
            return []
        }

        let state = CaptionGenerationState.shared
        if state.recordingID == recording.id, !state.segments.isEmpty {
            lastCaptionSource = .generationState
            return state.segments
        }

        let url = URL(fileURLWithPath: recording.filePath)
        let diskSegments = (try? SecurityScopedFileAccess.withAccess(to: url) {
            try CaptionEngine.shared.loadCaptions(for: url, recordingID: recording.id)
        }) ?? []
        if !diskSegments.isEmpty {
            lastCaptionSource = .sidecar
            return diskSegments
        }

        lastCaptionSource = .none
        return []
    }

    private func syncCaptionSources(recordingID: UUID, appState: AppState?) {
        captionSegmentsForExport = []
        captionStyleForExport = nil
        editorLeadingGapForExport = 0
        lastCaptionSource = .none

        guard let recording else { return }

        if let staged = appState?.consumeStagedExportCaptions(for: recordingID) {
            captionSegmentsForExport = staged.segments
            if let gap = staged.leadingGap {
                editorLeadingGapForExport = gap
            }
            captionStyleForExport = staged.style
            lastCaptionSource = .staged
        }

        if captionSegmentsForExport.isEmpty {
            let state = CaptionGenerationState.shared
            if state.recordingID == recordingID, !state.segments.isEmpty {
                captionSegmentsForExport = state.segments
                lastCaptionSource = .generationState
            }
        }

        if captionSegmentsForExport.isEmpty {
            let url = URL(fileURLWithPath: recording.filePath)
            let diskSegments = (try? SecurityScopedFileAccess.withAccess(to: url) {
                try CaptionEngine.shared.loadCaptions(for: url, recordingID: recordingID)
            }) ?? []
            if !diskSegments.isEmpty {
                captionSegmentsForExport = diskSegments
                lastCaptionSource = .sidecar
            }
        }

        if editorLeadingGapForExport < 0.001,
           recording.captionAudioLeadSeconds > 0.001 {
            editorLeadingGapForExport = recording.captionAudioLeadSeconds
        }

        if captionStyleForExport == nil {
            let url = URL(fileURLWithPath: recording.filePath)
            captionStyleForExport = CaptionEngine.shared.loadStyle(for: url, recordingID: recordingID)
        }

        if !captionSegmentsForExport.isEmpty {
            applyCaptions = true
        }
    }

    private func resolveLeadingGapIfNeeded(for recording: RecordingMetadata) async {
        guard editorLeadingGapForExport < 0.001 else { return }
        let url = URL(fileURLWithPath: recording.filePath)
        guard SecurityScopedFileAccess.canAccess(url) else { return }
        let asset = AVURLAsset(url: url)
        let probed = await RecordingMediaTiming.leadingVideoGapSeconds(
            asset: asset,
            metadataLead: recording.captionAudioLeadSeconds
        )
        if probed > 0.001 {
            editorLeadingGapForExport = probed
        } else if recording.captionAudioLeadSeconds > 0.001 {
            editorLeadingGapForExport = recording.captionAudioLeadSeconds
        }
    }
}
