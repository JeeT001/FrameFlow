//
//  EditorCompositionBuilder.swift
//  FrameFlow
//

import AVFoundation
import AppKit
import Foundation
import QuartzCore

enum EditorCompositionBuilder {
    /// Adds image overlay sublayers timed to export intervals (supports trim + middle cuts).
    static func addImageOverlay(
        _ overlay: EditorImageOverlay,
        timeline: EditTimelineModel,
        to parentLayer: CALayer,
        canvasSize: CGSize,
        videoRect: CGRect
    ) {
        guard let image = NSImage(contentsOf: overlay.fileURL),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return }

        let intervals = exportIntervalsForOverlay(overlay: overlay, timeline: timeline)
        guard !intervals.isEmpty else { return }

        let width = videoRect.width * overlay.normalizedWidth
        let height = width * (CGFloat(cgImage.height) / max(CGFloat(cgImage.width), 1))
        let centerX = videoRect.minX + videoRect.width * overlay.normalizedCenterX
        let centerY = videoRect.minY + videoRect.height * (1 - overlay.normalizedCenterY)
        let frame = CGRect(
            x: centerX - width / 2,
            y: centerY - height / 2,
            width: width,
            height: height
        )
        let opacity = Float(min(max(overlay.opacity, 0), 1))

        for interval in intervals {
            let imageLayer = CALayer()
            imageLayer.contents = cgImage
            imageLayer.contentsGravity = .resizeAspect
            imageLayer.frame = frame
            imageLayer.opacity = opacity
            imageLayer.beginTime = AVCoreAnimationBeginTimeAtZero + interval.exportStart
            imageLayer.duration = interval.duration
            parentLayer.addSublayer(imageLayer)
        }
    }

    /// Intersects overlay source interval with each kept range → export-timeline segments.
    static func exportIntervalsForOverlay(
        overlay: EditorImageOverlay,
        timeline: EditTimelineModel
    ) -> [(exportStart: Double, duration: Double)] {
        var result: [(exportStart: Double, duration: Double)] = []

        for kept in timeline.keptSourceRanges {
            let segStart = max(overlay.startSeconds, kept.start)
            let segEnd = min(overlay.endSeconds, kept.end)
            guard segEnd - segStart >= 0.01 else { continue }

            guard let exportStart = CaptionTimelineMapper.exportTime(
                fromSourceTime: segStart,
                editTimeline: timeline
            ),
            let exportEnd = CaptionTimelineMapper.exportTime(
                fromSourceTime: segEnd,
                editTimeline: timeline
            ),
            exportEnd > exportStart else { continue }

            result.append((exportStart, exportEnd - exportStart))
        }

        return result
    }

    /// Inserts imported audio for the clip duration on the export timeline.
    static func insertImportedAudio(
        _ audio: EditorImportedAudio,
        into composition: AVMutableComposition,
        compositionDurationSeconds: Double
    ) async throws {
        let asset = AVURLAsset(url: audio.fileURL)
        guard let sourceTrack = try await asset.loadTracks(withMediaType: .audio).first else { return }

        let sourceDuration = try await asset.load(.duration)
        let sourceSeconds = CMTimeGetSeconds(sourceDuration)

        let exportStart = max(0, audio.timelineStartSeconds)
        let clipDuration = audio.playDuration
        guard clipDuration > 0.01 else { return }

        let sourceTrimStart = max(0, min(audio.sourceTrimStartSeconds, sourceSeconds))
        let sourceTrimEnd = min(sourceSeconds, max(audio.sourceTrimEndSeconds, sourceTrimStart + 0.01))
        let availableSource = sourceTrimEnd - sourceTrimStart
        let insertSeconds = min(clipDuration, availableSource, max(0, compositionDurationSeconds - exportStart))
        guard insertSeconds > 0.01 else { return }

        let sourceRange = CMTimeRange(
            start: CMTime(seconds: sourceTrimStart, preferredTimescale: 600),
            duration: CMTime(seconds: insertSeconds, preferredTimescale: 600)
        )
        let exportStartTime = CMTime(seconds: exportStart, preferredTimescale: 600)

        guard let compositionTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else { return }

        try compositionTrack.insertTimeRange(
            sourceRange,
            of: sourceTrack,
            at: exportStartTime
        )
        compositionTrack.preferredVolume = Float(min(max(audio.volume, 0), 1))
    }

    /// Maps a source-timeline interval to export-timeline start/duration (nil if fully removed).
    static func exportInterval(
        sourceStart: Double,
        sourceEnd: Double,
        timeline: EditTimelineModel
    ) -> (start: Double, duration: Double)? {
        guard let exportStart = CaptionTimelineMapper.exportTime(fromSourceTime: sourceStart, editTimeline: timeline),
              let exportEnd = CaptionTimelineMapper.exportTime(fromSourceTime: sourceEnd, editTimeline: timeline),
              exportEnd > exportStart
        else { return nil }

        return (exportStart, exportEnd - exportStart)
    }
}
