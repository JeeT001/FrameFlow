//
//  ExportService.swift
//  FrameFlow
//

import AVFoundation
import AppKit
import Foundation
import QuartzCore
import UserNotifications

enum ExportResolution: String, CaseIterable, Sendable, Identifiable {
    case p720 = "720p"
    case p1080 = "1080p"
    case p4K = "4K"

    var id: String { rawValue }

    var displayName: String { rawValue }

    func targetSize(isPortrait: Bool) -> CGSize {
        switch self {
        case .p720:
            return isPortrait ? CGSize(width: 720, height: 1280) : CGSize(width: 1280, height: 720)
        case .p1080:
            return isPortrait ? CGSize(width: 1080, height: 1920) : CGSize(width: 1920, height: 1080)
        case .p4K:
            return isPortrait ? CGSize(width: 2160, height: 3840) : CGSize(width: 3840, height: 2160)
        }
    }
}

struct ExportOptions: Sendable {
    let sourceVideoURL: URL
    let recordingID: UUID
    let resolution: ExportResolution
    let isPro: Bool
    let applyCaptionsIfAvailable: Bool
    let captionStyle: CaptionStyleConfig
    let outputFilename: String
    let editTimeline: EditTimelineModel?
    let editorProject: EditorProjectModel?
    /// Leading gap before first video sample in the source file (legacy recordings).
    let leadingVideoGapSeconds: Double
    /// Editor preview leading gap — preferred over metadata when > 0 (matches `CaptionEditorViewModel.videoContentStartSeconds`).
    let editorLeadingVideoGapSeconds: Double
    /// In-memory caption segments from the editor preview (preferred over sidecar load).
    let captionSegments: [CaptionSegment]?
    /// When true, Pass B encode must not re-trim leading gap (source already trimmed during burn-in).
    let skipLeadingGapTrim: Bool
}

enum ExportServiceError: LocalizedError {
    case noVideoTrack
    case exportFailed(String)
    case saveFolderUnavailable
    case diskFull
    case captionsRequiredButUnavailable
    case captionsTrimmedEmpty

    var errorDescription: String? {
        switch self {
        case .noVideoTrack:
            return "No video track found in this recording."
        case .exportFailed(let detail):
            return "Export failed: \(detail)"
        case .saveFolderUnavailable:
            return "Could not access the save folder. Choose a folder in Settings."
        case .diskFull:
            return ExportDiskSpaceChecker.diskFullMessage
        case .captionsRequiredButUnavailable:
            return "Captions are enabled but no caption data was found. Generate captions in the editor and try again."
        case .captionsTrimmedEmpty:
            return "Captions fall outside the visible video after sync trim. Regenerate captions and try export again."
        }
    }
}

final class ExportService: @unchecked Sendable {
    static let shared = ExportService()

    private let captionEngine = CaptionEngine.shared
    private let captionRenderer = CaptionRenderer.shared
    private let fileManager = FileManager.default

    private init() {}

    func export(
        options: ExportOptions,
        progress: @Sendable (Double, String) -> Void
    ) async throws -> URL {
        return try await SecurityScopedFileAccess.withAccess(to: options.sourceVideoURL) {
            progress(0.05, "Preparing export…")

            let originalAsset = AVURLAsset(url: options.sourceVideoURL)
            let probedLeadingGap = await RecordingMediaTiming.leadingVideoGapSeconds(
                asset: originalAsset,
                metadataLead: nil
            )
            let resolvedLeadingGap = CaptionExportTimeline.resolvedLeadingGap(
                editorLeadingGap: options.editorLeadingVideoGapSeconds,
                metadataLead: options.leadingVideoGapSeconds,
                probedFromAsset: probedLeadingGap
            )
            let trackDurations = await RecordingMediaTiming.probeTrackDurations(asset: originalAsset)

            #if DEBUG
            print(
                "[ExportService] resolvedLeadingGap=\(String(format: "%.3f", resolvedLeadingGap))s " +
                "audio=\(String(format: "%.2f", trackDurations.audioSeconds))s " +
                "video=\(String(format: "%.2f", trackDurations.videoSeconds))s"
            )
            #endif

            var sourceURL = options.sourceVideoURL
            var tempCaptionURL: URL?
            var skipLeadingGapTrim = options.skipLeadingGapTrim

            defer {
                if let tempCaptionURL {
                    try? fileManager.removeItem(at: tempCaptionURL)
                }
            }

            if options.applyCaptionsIfAvailable {
                var segments = options.captionSegments ?? []
                if segments.isEmpty {
                    segments = try captionEngine.loadCaptions(
                        for: options.sourceVideoURL,
                        recordingID: options.recordingID
                    )
                }
                let timeline = (options.editorProject ?? options.editTimeline.map {
                    EditorProjectModel(timeline: $0)
                })?.preparedForExport().timeline
                if let timeline, timeline.requiresStitchExport {
                    segments = CaptionTimelineMapper.segmentsForSourceBurnIn(
                        from: segments,
                        editTimeline: timeline
                    )
                }
                guard !segments.isEmpty else {
                    throw ExportServiceError.captionsRequiredButUnavailable
                }

                let burnSegments = CaptionExportTimeline.segmentsForBurnIn(
                    from: segments,
                    leadingGap: resolvedLeadingGap,
                    audioDuration: trackDurations.audioSeconds,
                    videoDuration: trackDurations.videoSeconds
                )
                guard !burnSegments.isEmpty else {
                    throw ExportServiceError.captionsTrimmedEmpty
                }

                #if DEBUG
                print(
                    "[ExportService] burn-in segments=\(burnSegments.count) " +
                    "first=\(String(format: "%.2f", burnSegments.first?.startTime ?? -1))s " +
                    "lastEnd=\(String(format: "%.2f", burnSegments.last?.endTime ?? -1))s"
                )
                #endif

                progress(0.12, "Burning in captions…")
                let temp = fileManager.temporaryDirectory
                    .appendingPathComponent("frameflow_export_captions_\(UUID().uuidString).mp4")
                try await captionRenderer.burnInCaptions(
                    videoURL: sourceURL,
                    segments: burnSegments,
                    style: options.captionStyle,
                    outputURL: temp,
                    leadingVideoGapSeconds: resolvedLeadingGap
                )
                tempCaptionURL = temp
                sourceURL = temp
                skipLeadingGapTrim = true
            }

            progress(0.3, "Encoding at \(options.resolution.displayName)…")

            let outputURL = try await writeEncodedExport(
                sourceURL: sourceURL,
                outputFilename: options.outputFilename,
                resolution: options.resolution,
                applyWatermark: !options.isPro,
                editorProject: options.editorProject ?? options.editTimeline.map {
                    EditorProjectModel(timeline: $0)
                }?.preparedForExport(),
                leadingVideoGapSeconds: skipLeadingGapTrim ? 0 : resolvedLeadingGap,
                skipLeadingGapTrim: skipLeadingGapTrim,
                progress: progress
            )

            progress(1.0, "Export complete.")
            await notifyExportComplete(filename: outputURL.lastPathComponent)
            return outputURL
        }
    }

    static func captionStyle(for sourceURL: URL, recordingID: UUID) -> CaptionStyleConfig {
        CaptionEngine.shared.loadStyle(for: sourceURL, recordingID: recordingID)
    }

    // MARK: - Encode

    private func writeEncodedExport(
        sourceURL: URL,
        outputFilename: String,
        resolution: ExportResolution,
        applyWatermark: Bool,
        editorProject: EditorProjectModel?,
        leadingVideoGapSeconds: Double,
        skipLeadingGapTrim: Bool,
        progress: @Sendable (Double, String) -> Void
    ) async throws -> URL {
        let asset = AVURLAsset(url: sourceURL)
        let sourceVideoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let sourceVideoTrack = sourceVideoTracks.first else {
            throw ExportServiceError.noVideoTrack
        }

        let fullDuration = try await asset.load(.duration)
        let fullSeconds = CMTimeGetSeconds(fullDuration)

        let leadingGap: Double
        if skipLeadingGapTrim {
            leadingGap = 0
        } else {
            leadingGap = await RecordingMediaTiming.leadingVideoGapSeconds(
                asset: asset,
                metadataLead: leadingVideoGapSeconds > 0.001 ? leadingVideoGapSeconds : nil
            )
        }

        let project = editorProject
        let timeline = project?.timeline
        let keptRanges: [KeptSourceRange]
        let expectedExportSeconds: Double

        let videoExportSeconds: Double
        if let timeline, timeline.requiresStitchExport {
            keptRanges = RecordingMediaTiming.adjustedKeptRanges(
                timeline.keptSourceRanges.filter { $0.duration > 0.001 },
                leadingGap: leadingGap,
                sourceDuration: fullSeconds
            )
            videoExportSeconds = keptRanges.reduce(0) { $0 + $1.duration }
            #if DEBUG
            if timeline.hasRemovedRegions {
                print("[Export] stitch ranges=\(keptRanges.count) videoExport=\(videoExportSeconds)s")
            }
            #endif
        } else {
            keptRanges = RecordingMediaTiming.adjustedKeptRanges(
                [KeptSourceRange(start: 0, end: fullSeconds)],
                leadingGap: leadingGap,
                sourceDuration: fullSeconds
            )
            videoExportSeconds = keptRanges.first?.duration ?? max(0, fullSeconds - leadingGap)
        }

        guard !keptRanges.isEmpty else {
            throw ExportServiceError.exportFailed("No video content after trimming leading gap.")
        }

        let masterSeconds = project?.masterTimelineDurationSeconds ?? videoExportSeconds
        expectedExportSeconds = max(videoExportSeconds, masterSeconds)

        let exportDuration = CMTime(seconds: expectedExportSeconds, preferredTimescale: 600)
        let naturalSize = try await sourceVideoTrack.load(.naturalSize)
        let preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
        var renderSize = naturalSize.applying(preferredTransform)
        renderSize = CGSize(width: abs(renderSize.width), height: abs(renderSize.height))
        let isPortrait = renderSize.height > renderSize.width
        let targetSize = resolution.targetSize(isPortrait: isPortrait)

        let scale = min(targetSize.width / renderSize.width, targetSize.height / renderSize.height)
        let scaledWidth = renderSize.width * scale
        let scaledHeight = renderSize.height * scale
        let xOffset = (targetSize.width - scaledWidth) / 2
        let yOffset = (targetSize.height - scaledHeight) / 2

        let composition = AVMutableComposition()
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw ExportServiceError.exportFailed("Could not create video track.")
        }

        var insertCursor = CMTime.zero
        for range in keptRanges {
            let rangeDuration = CMTime(seconds: range.duration, preferredTimescale: 600)
            guard rangeDuration.seconds > 0 else { continue }
            let sourceRange = CMTimeRange(
                start: CMTime(seconds: range.start, preferredTimescale: 600),
                duration: rangeDuration
            )
            try compositionVideoTrack.insertTimeRange(
                sourceRange,
                of: sourceVideoTrack,
                at: insertCursor
            )
            insertCursor = CMTimeAdd(insertCursor, rangeDuration)
        }

        if let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(
               withMediaType: .audio,
               preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            insertCursor = .zero
            for range in keptRanges {
                let rangeDuration = CMTime(seconds: range.duration, preferredTimescale: 600)
                guard rangeDuration.seconds > 0 else { continue }
                let sourceRange = CMTimeRange(
                    start: CMTime(seconds: range.start, preferredTimescale: 600),
                    duration: rangeDuration
                )
                try compositionAudioTrack.insertTimeRange(
                    sourceRange,
                    of: sourceAudioTrack,
                    at: insertCursor
                )
                insertCursor = CMTimeAdd(insertCursor, rangeDuration)
            }
        }

        if let tracks = project?.importedAudioTracks {
            for importedAudio in tracks {
                try await SecurityScopedFileAccess.withAccess(to: importedAudio.fileURL) {
                    try await EditorCompositionBuilder.insertImportedAudio(
                        importedAudio,
                        into: composition,
                        compositionDurationSeconds: expectedExportSeconds
                    )
                }
            }
        }

        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: targetSize)
        parentLayer.isGeometryFlipped = true

        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: xOffset, y: yOffset, width: scaledWidth, height: scaledHeight)

        let videoRect = CGRect(x: xOffset, y: yOffset, width: scaledWidth, height: scaledHeight)

        let hasImageOverlays = !(project?.imageOverlays.isEmpty ?? true)
        let needsCoreAnimationCompositor = applyWatermark || hasImageOverlays

        if needsCoreAnimationCompositor {
            parentLayer.addSublayer(videoLayer)
        }

        if hasImageOverlays, let overlays = project?.imageOverlays, let timeline = project?.timeline.preparedForExport() {
            for overlay in overlays {
                EditorCompositionBuilder.addImageOverlay(
                    overlay,
                    timeline: timeline,
                    to: parentLayer,
                    canvasSize: targetSize,
                    videoRect: videoRect
                )
            }
        }

        if applyWatermark {
            WatermarkCompositor.add(to: parentLayer, canvasSize: targetSize)
        }

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = targetSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        if needsCoreAnimationCompositor {
            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
                postProcessingAsVideoLayer: videoLayer,
                in: parentLayer
            )
        }

        let finalTransform = preferredTransform
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(translationX: xOffset, y: yOffset))

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: exportDuration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstruction.setTransform(finalTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        progress(0.55, "Writing file…")

        return try await SecurityScopedFileAccess.withSaveFolderAccess(
            fallbackURL: fallbackRecordingsDirectory()
        ) { folderURL in
            guard ExportDiskSpaceChecker.hasSufficientSpace(at: folderURL) else {
                throw ExportServiceError.diskFull
            }

            let outputURL = folderURL.appendingPathComponent(outputFilename)

            if fileManager.fileExists(atPath: outputURL.path) {
                try fileManager.removeItem(at: outputURL)
            }

            guard let exportSession = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetHighestQuality
            ) else {
                throw ExportServiceError.exportFailed("Export session unavailable.")
            }

            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.videoComposition = videoComposition

            await exportSession.export()

            if let error = exportSession.error {
                if ExportDiskSpaceChecker.isDiskFullError(error) {
                    throw ExportServiceError.diskFull
                }
                throw ExportServiceError.exportFailed(error.localizedDescription)
            }
            guard exportSession.status == .completed else {
                throw ExportServiceError.exportFailed("Export status \(exportSession.status.rawValue).")
            }

        if timeline?.requiresStitchExport == true || project?.hasMediaLayers == true {
                let outAsset = AVURLAsset(url: outputURL)
                let outDuration = try await outAsset.load(.duration)
                let outSeconds = CMTimeGetSeconds(outDuration)
                if abs(outSeconds - expectedExportSeconds) > 1.0 {
                    throw ExportServiceError.exportFailed(
                        "Export duration mismatch: got \(String(format: "%.1f", outSeconds))s " +
                        "expected \(String(format: "%.1f", expectedExportSeconds))s"
                    )
                }
            }

            return outputURL
        }
    }

    // MARK: - Save folder

    private func fallbackRecordingsDirectory() -> URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FrameFlow/Recordings", isDirectory: true)
    }

    // MARK: - Notifications

    private func notifyExportComplete(filename: String) async {
        guard SettingsStore.shared.notificationsEnabled else { return }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }

        let content = UNMutableNotificationContent()
        content.title = "Export complete"
        content.body = "Saved \(filename) to your save folder."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "frameflow.export.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        try? await center.add(request)
    }
}

// MARK: - Free-tier export watermark (blueprint Day 28)

/// Renders `AppBranding.watermarkText` on the **full letterboxed canvas** (16:9 and 9:16).
/// Padding and font size scale from a 1080p-tall reference so 10pt padding matches blueprint at 1080p.
private enum WatermarkCompositor {
    static let watermarkText = AppBranding.watermarkText
    static let referenceCanvasHeight: CGFloat = 1080
    static let referencePaddingPoints: CGFloat = 10
    static let referenceFontSize: CGFloat = 13
    static let textOpacity: CGFloat = 0.8

    static func add(to parent: CALayer, canvasSize: CGSize) {
        let scale = canvasSize.height / referenceCanvasHeight
        let padding = referencePaddingPoints * scale
        let fontSize = max(11, referenceFontSize * scale)
        let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)

        let textLayer = CATextLayer()
        textLayer.string = watermarkText
        textLayer.font = font
        textLayer.fontSize = font.pointSize
        textLayer.foregroundColor = NSColor.white.withAlphaComponent(textOpacity).cgColor
        textLayer.alignmentMode = .left
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        textLayer.shadowColor = NSColor.black.cgColor
        textLayer.shadowOpacity = 0.55
        textLayer.shadowRadius = 2 * scale
        textLayer.shadowOffset = CGSize(width: 0, height: -1)

        let textBounds = (watermarkText as NSString).boundingRect(
            with: CGSize(width: canvasSize.width * 0.6, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        ).integral

        let pillInsetH = 6 * scale
        let pillInsetV = 3 * scale
        let pillWidth = textBounds.width + pillInsetH * 2
        let pillHeight = textBounds.height + pillInsetV * 2

        // Parent uses isGeometryFlipped — origin top-left; anchor to canvas bottom-left (includes letterbox bars).
        let originX = padding
        let originY = canvasSize.height - padding - pillHeight

        let pillLayer = CALayer()
        pillLayer.backgroundColor = NSColor.black.withAlphaComponent(0.32).cgColor
        pillLayer.cornerRadius = 4 * scale
        pillLayer.frame = CGRect(x: originX, y: originY, width: pillWidth, height: pillHeight)
        pillLayer.beginTime = AVCoreAnimationBeginTimeAtZero
        pillLayer.duration = 1e6

        textLayer.frame = CGRect(
            x: originX + pillInsetH,
            y: originY + pillInsetV,
            width: textBounds.width,
            height: textBounds.height
        )
        textLayer.beginTime = AVCoreAnimationBeginTimeAtZero
        textLayer.duration = 1e6

        parent.addSublayer(pillLayer)
        parent.addSublayer(textLayer)
    }
}
