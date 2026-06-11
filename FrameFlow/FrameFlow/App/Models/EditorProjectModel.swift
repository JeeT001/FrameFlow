//
//  EditorProjectModel.swift
//  FrameFlow
//

import AppKit
import CoreGraphics
import Foundation

/// Image overlay imported for the current edit session (Editor 2.0).
struct EditorImageOverlay: Equatable, Sendable, Identifiable {
    var id: UUID = UUID()
    var fileURL: URL
    /// Visible interval on the **source** timeline (seconds).
    var startSeconds: Double
    var endSeconds: Double
    var opacity: Double = 1.0
    /// Normalized center: x 0=left, 1=right; y 0=bottom, 1=top (matches PiP conventions).
    var normalizedCenterX: Double = 0.84
    var normalizedCenterY: Double = 0.18
    /// Width as a fraction of the video canvas width.
    var normalizedWidth: Double = 0.24

    var duration: Double { max(0, endSeconds - startSeconds) }

    static let defaultClipDuration: Double = 5.0

    func contains(playhead: Double) -> Bool {
        playhead >= startSeconds && playhead <= endSeconds
    }

    /// Clamps the clip inside trim bounds while preserving duration when possible.
    func clampedInterval(
        trimStart: Double,
        trimEnd: Double,
        minSpan: Double = EditTimelineModel.minimumSpanSeconds
    ) -> (start: Double, end: Double) {
        var start = max(startSeconds, trimStart)
        var end = min(endSeconds, trimEnd)

        if end - start < minSpan {
            let desired = max(minSpan, min(duration, trimEnd - trimStart))
            start = max(trimStart, min(start, trimEnd - desired))
            end = min(trimEnd, start + desired)
            start = max(trimStart, end - desired)
        }

        return (start, end)
    }

    static func defaultInterval(
        playhead: Double,
        trimStart: Double,
        trimEnd: Double,
        clipDuration: Double = defaultClipDuration
    ) -> (start: Double, end: Double) {
        let minSpan = EditTimelineModel.minimumSpanSeconds
        let start = max(trimStart, playhead - 1)
        let end = min(trimEnd, start + clipDuration)
        if end - start < minSpan {
            let adjustedEnd = min(trimEnd, start + minSpan)
            let adjustedStart = max(trimStart, adjustedEnd - minSpan)
            return (adjustedStart, adjustedEnd)
        }
        return (start, end)
    }

    static let normalizedWidthRange: ClosedRange<Double> = 0.08...0.75
    static let edgeMargin: Double = 0.02

    static func imageAspectRatio(for url: URL) -> Double {
        guard let image = NSImage(contentsOf: url) else { return 1 }
        return image.size.height / max(image.size.width, 1)
    }

    /// Image height as a fraction of container height.
    func normalizedHeightFraction(containerAspect: Double, imageAspect: Double) -> Double {
        guard containerAspect > 0 else { return normalizedWidth }
        return normalizedWidth * imageAspect / containerAspect
    }

    func clampedWidth(_ width: Double) -> Double {
        min(max(width, Self.normalizedWidthRange.lowerBound), Self.normalizedWidthRange.upperBound)
    }

    /// Keeps the full image frame inside the preview (normalizedCenterY: 0 = bottom, 1 = top).
    func clampedCenter(
        x: Double,
        y: Double,
        normalizedWidth widthOverride: Double? = nil,
        containerAspect: Double,
        imageAspect: Double
    ) -> (x: Double, y: Double) {
        let width = clampedWidth(widthOverride ?? normalizedWidth)
        let halfW = width / 2
        let halfH = Self.heightFraction(width: width, containerAspect: containerAspect, imageAspect: imageAspect) / 2
        let margin = Self.edgeMargin
        let minX = halfW + margin
        let maxX = max(minX, 1 - halfW - margin)
        let minY = halfH + margin
        let maxY = max(minY, 1 - halfH - margin)
        return (
            min(max(x, minX), maxX),
            min(max(y, minY), maxY)
        )
    }

    private static func heightFraction(
        width: Double,
        containerAspect: Double,
        imageAspect: Double
    ) -> Double {
        guard containerAspect > 0 else { return width }
        return width * imageAspect / containerAspect
    }
}

/// Imported audio mixed into the export (Editor 2.0).
struct EditorImportedAudio: Equatable, Sendable, Identifiable {
    var id: UUID = UUID()
    var fileURL: URL
    /// Where the clip begins on the **master/export** timeline (seconds).
    var timelineStartSeconds: Double = 0
    /// Where the clip ends on the **master/export** timeline (seconds).
    var timelineEndSeconds: Double = 0
    /// Trim in-point inside the audio **file** (seconds).
    var sourceTrimStartSeconds: Double = 0
    /// Trim out-point inside the audio **file** (seconds).
    var sourceTrimEndSeconds: Double = 0
    var volume: Double = 1.0
    var sourceDurationSeconds: Double

    var playDuration: Double {
        max(0, timelineEndSeconds - timelineStartSeconds)
    }

    var sourceTrimDuration: Double {
        max(0, sourceTrimEndSeconds - sourceTrimStartSeconds)
    }

    /// Seconds of source audio used (timeline clip length capped by source trim window).
    var effectiveSourcePlaySeconds: Double {
        min(playDuration, sourceTrimDuration)
    }

    /// Full-length import: clip spans entire file; master timeline may extend beyond video.
    static func importedFullLength(
        fileURL: URL,
        sourceDuration: Double,
        timelineStart: Double = 0
    ) -> EditorImportedAudio {
        EditorImportedAudio(
            fileURL: fileURL,
            timelineStartSeconds: timelineStart,
            timelineEndSeconds: timelineStart + sourceDuration,
            sourceTrimStartSeconds: 0,
            sourceTrimEndSeconds: sourceDuration,
            volume: 1.0,
            sourceDurationSeconds: sourceDuration
        )
    }

    mutating func clampTimelineToMaster(
        minSpan: Double = EditTimelineModel.minimumSpanSeconds
    ) {
        timelineStartSeconds = max(0, timelineStartSeconds)
        let maxPlay = sourceTrimDuration
        timelineEndSeconds = min(
            max(timelineEndSeconds, timelineStartSeconds + minSpan),
            timelineStartSeconds + maxPlay
        )
        clampSourceTrim()
    }

    mutating func clampSourceTrim(
        minSpan: Double = EditTimelineModel.minimumSpanSeconds
    ) {
        sourceTrimStartSeconds = max(0, min(sourceTrimStartSeconds, sourceDurationSeconds - minSpan))
        sourceTrimEndSeconds = min(
            sourceDurationSeconds,
            max(sourceTrimEndSeconds, sourceTrimStartSeconds + minSpan)
        )
        let maxPlay = sourceTrimDuration
        if playDuration > maxPlay {
            timelineEndSeconds = timelineStartSeconds + maxPlay
        }
    }
}

/// Single-clip edit session: timeline edits + optional overlay/audio layers.
struct EditorProjectModel: Equatable, Sendable {
    var timeline: EditTimelineModel
    var imageOverlays: [EditorImageOverlay] = []
    var importedAudioTracks: [EditorImportedAudio] = []

    var videoExportDurationSeconds: Double { timeline.exportDurationSeconds }
    var exportDurationSeconds: Double { masterTimelineDurationSeconds }

    /// Longest audio clip end defines extension past video (editor-style master ruler).
    var masterTimelineDurationSeconds: Double {
        let videoEnd = timeline.exportDurationSeconds
        let audioEnd = importedAudioTracks.map(\.timelineEndSeconds).max() ?? 0
        return max(videoEnd, audioEnd)
    }

    var hasAudioTimelineExtension: Bool {
        guard let audioEnd = importedAudioTracks.map(\.timelineEndSeconds).max() else { return false }
        return audioEnd > timeline.exportDurationSeconds + 0.01
    }

    var requiresStitchExport: Bool { timeline.requiresStitchExport }
    var hasMediaLayers: Bool { !imageOverlays.isEmpty || !importedAudioTracks.isEmpty }
    var isFullSourceExport: Bool {
        timeline.isFullSourceExport && !hasMediaLayers && !hasAudioTimelineExtension
    }

    init(timeline: EditTimelineModel = EditTimelineModel()) {
        self.timeline = timeline
    }

    func preparedForExport() -> EditorProjectModel {
        var model = self
        model.timeline = timeline.preparedForExport()
        return model
    }

    mutating func configureSourceDuration(_ duration: Double) {
        timeline.configureSourceDuration(duration)
        for index in imageOverlays.indices {
            let interval = imageOverlays[index].clampedInterval(
                trimStart: timeline.trimStartSeconds,
                trimEnd: timeline.trimEndSeconds
            )
            imageOverlays[index].startSeconds = interval.start
            imageOverlays[index].endSeconds = interval.end
        }
        for index in importedAudioTracks.indices {
            importedAudioTracks[index].clampTimelineToMaster()
        }
    }
}
