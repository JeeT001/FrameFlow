//
//  CaptionRenderer.swift
//  FrameFlow
//

import AVFoundation
import AppKit
import QuartzCore

enum CaptionRendererError: LocalizedError {
    case noVideoTrack
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .noVideoTrack:
            return "No video track found for caption burn-in."
        case .exportFailed(let detail):
            return "Caption export failed: \(detail)"
        }
    }
}

final class CaptionRenderer: @unchecked Sendable {
    static let shared = CaptionRenderer()

    private init() {}

    func writeSRT(segments: [CaptionSegment], to url: URL) throws {
        let cleaned = WhisperTranscriptSanitizer.sanitizedSegments(from: segments)
        var lines: [String] = []
        for (index, segment) in cleaned.enumerated() {
            let number = index + 1
            let start = srtTimestamp(segment.startTime)
            let end = srtTimestamp(segment.endTime)
            lines.append("\(number)")
            lines.append("\(start) --> \(end)")
            lines.append(segment.text)
            lines.append("")
        }

        let body = lines.joined(separator: "\n")
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try body.write(to: url, atomically: true, encoding: .utf8)
    }

    func burnInCaptions(
        videoURL: URL,
        segments: [CaptionSegment],
        style: CaptionStyleConfig,
        outputURL: URL,
        leadingVideoGapSeconds: Double = 0
    ) async throws {
        let cleaned = WhisperTranscriptSanitizer.sanitizedSegments(from: segments)
        guard !cleaned.isEmpty else {
            throw CaptionRendererError.exportFailed("No caption segments to burn in.")
        }

        let asset = AVURLAsset(url: videoURL)
        let sourceVideoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let sourceVideoTrack = sourceVideoTracks.first else {
            throw CaptionRendererError.noVideoTrack
        }

        let fullDuration = try await asset.load(.duration)
        let fullSeconds = CMTimeGetSeconds(fullDuration)
        let leadingGap = max(0, leadingVideoGapSeconds)
        let exportSeconds = max(0.05, fullSeconds - leadingGap)
        let exportDuration = CMTime(seconds: exportSeconds, preferredTimescale: 600)

        let composition = AVMutableComposition()

        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw CaptionRendererError.exportFailed("Could not create composition video track.")
        }

        let sourceStart = CMTime(seconds: leadingGap, preferredTimescale: 600)
        try compositionVideoTrack.insertTimeRange(
            CMTimeRange(start: sourceStart, duration: exportDuration),
            of: sourceVideoTrack,
            at: .zero
        )

        if let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(
               withMediaType: .audio,
               preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            try compositionAudioTrack.insertTimeRange(
                CMTimeRange(start: sourceStart, duration: exportDuration),
                of: sourceAudioTrack,
                at: .zero
            )
        }

        let naturalSize = try await sourceVideoTrack.load(.naturalSize)
        let preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
        var renderSize = naturalSize.applying(preferredTransform)
        renderSize = CGSize(width: abs(renderSize.width), height: abs(renderSize.height))

        compositionVideoTrack.preferredTransform = preferredTransform

        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: renderSize)
        parentLayer.isGeometryFlipped = true
        parentLayer.beginTime = AVCoreAnimationBeginTimeAtZero
        parentLayer.duration = exportSeconds

        let videoLayer = CALayer()
        videoLayer.frame = parentLayer.bounds
        videoLayer.beginTime = AVCoreAnimationBeginTimeAtZero
        parentLayer.addSublayer(videoLayer)

        let effectiveStyle = resolvedStyle(style)
        addCaptionLayers(to: parentLayer, segments: cleaned, style: effectiveStyle, renderSize: renderSize)

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: exportDuration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstruction.setTransform(preferredTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw CaptionRendererError.exportFailed("Export session unavailable.")
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition

        await exportSession.export()

        if let error = exportSession.error {
            throw CaptionRendererError.exportFailed(error.localizedDescription)
        }
        guard exportSession.status == .completed else {
            throw CaptionRendererError.exportFailed("Export status \(exportSession.status.rawValue).")
        }
    }

    // MARK: - Layer building

    /// Core Animation replaces `beginTime == 0` with `CACurrentMediaTime()` during offline export.
    private func timelineTime(_ seconds: Double) -> CFTimeInterval {
        AVCoreAnimationBeginTimeAtZero + max(0, seconds)
    }

    /// Pins each caption layer to its segment window on the video timeline (required for long exports).
    private func configureTimedLayer(
        _ layer: CALayer,
        startTime: Double,
        duration: Double,
        visibleOpacity: Float = 1
    ) {
        let segmentDuration = max(0.05, duration)
        let begin = timelineTime(startTime)
        layer.beginTime = begin
        layer.duration = segmentDuration
        layer.opacity = 0

        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.beginTime = begin
        animation.duration = segmentDuration
        animation.values = [0, visibleOpacity, visibleOpacity, 0]
        animation.keyTimes = [0, 0.01, 0.99, 1]
        animation.fillMode = .both
        animation.isRemovedOnCompletion = false
        layer.add(animation, forKey: "captionOpacity")
    }

    private func resolvedStyle(_ style: CaptionStyleConfig) -> CaptionStyleConfig {
        switch style.preset {
        case .custom:
            var fallback = CaptionStyleConfig.classic
            fallback.preset = .custom
            return fallback
        default:
            return style
        }
    }

    private func addCaptionLayers(
        to parentLayer: CALayer,
        segments: [CaptionSegment],
        style: CaptionStyleConfig,
        renderSize: CGSize
    ) {
        for segment in segments {
            switch style.preset {
            case .tiktokBold:
                addWordLayers(for: segment, style: style, renderSize: renderSize, parent: parentLayer)
            case .highlightedWord:
                addHighlightedWordLayers(for: segment, style: style, renderSize: renderSize, parent: parentLayer)
            default:
                let layer = makeTextLayer(text: segment.text, style: style, renderSize: renderSize)
                configureTimedLayer(
                    layer,
                    startTime: segment.startTime,
                    duration: segment.endTime - segment.startTime
                )
                parentLayer.addSublayer(layer)
            }
        }
    }

    private func addHighlightedWordLayers(
        for segment: CaptionSegment,
        style: CaptionStyleConfig,
        renderSize: CGSize,
        parent: CALayer
    ) {
        let words = segment.text.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return }

        let totalDuration = max(0.05, segment.endTime - segment.startTime)
        let wordDuration = totalDuration / Double(words.count)

        for (index, word) in words.enumerated() {
            let wordStart = segment.startTime + Double(index) * wordDuration

            let dimLayer = makeTextLayer(text: segment.text, style: style, renderSize: renderSize)
            configureTimedLayer(dimLayer, startTime: wordStart, duration: wordDuration, visibleOpacity: 0.45)
            parent.addSublayer(dimLayer)

            let highlightLayer = makeTextLayer(text: word, style: style, renderSize: renderSize)
            highlightLayer.foregroundColor = NSColor.systemYellow.cgColor
            configureTimedLayer(highlightLayer, startTime: wordStart, duration: wordDuration)
            parent.addSublayer(highlightLayer)
        }
    }

    private func addWordLayers(
        for segment: CaptionSegment,
        style: CaptionStyleConfig,
        renderSize: CGSize,
        parent: CALayer
    ) {
        let words = segment.text.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return }

        let totalDuration = max(0.05, segment.endTime - segment.startTime)
        let wordDuration = totalDuration / Double(words.count)

        for (index, word) in words.enumerated() {
            let wordStart = segment.startTime + Double(index) * wordDuration
            let layer = makeTextLayer(text: word.uppercased(), style: style, renderSize: renderSize)
            configureTimedLayer(layer, startTime: wordStart, duration: wordDuration)
            parent.addSublayer(layer)
        }
    }

    private func makeTextLayer(text: String, style: CaptionStyleConfig, renderSize: CGSize) -> CATextLayer {
        let fontSize = CaptionLayoutMath.scaledFontSize(style: style, containerHeight: renderSize.height)
        let font = NSFont(name: style.fontName, size: fontSize) ?? NSFont.boldSystemFont(ofSize: fontSize)

        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.font = font
        textLayer.fontSize = font.pointSize
        textLayer.foregroundColor = style.nsTextColor.cgColor
        textLayer.alignmentMode = .center
        textLayer.isWrapped = true
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2

        let frame = CaptionLayoutMath.captionFrame(style: style, containerSize: renderSize)
        textLayer.frame = frame

        if style.showsBackground, let background = style.nsBackgroundColor {
            let cornerRadius = CaptionLayoutMath.cornerRadius(style: style, containerHeight: renderSize.height)
            textLayer.backgroundColor = background.cgColor
            textLayer.cornerRadius = cornerRadius
        }

        return textLayer
    }

    private func srtTimestamp(_ seconds: Double) -> String {
        let totalMilliseconds = max(0, Int((seconds * 1000).rounded()))
        let hours = totalMilliseconds / 3_600_000
        let minutes = (totalMilliseconds % 3_600_000) / 60_000
        let secs = (totalMilliseconds % 60_000) / 1000
        let milliseconds = totalMilliseconds % 1000
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, secs, milliseconds)
    }
}
