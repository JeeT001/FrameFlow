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
        var lines: [String] = []
        for (index, segment) in segments.enumerated() {
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
        outputURL: URL
    ) async throws {
        let asset = AVURLAsset(url: videoURL)
        let sourceVideoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let sourceVideoTrack = sourceVideoTracks.first else {
            throw CaptionRendererError.noVideoTrack
        }

        let duration = try await asset.load(.duration)
        let composition = AVMutableComposition()

        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw CaptionRendererError.exportFailed("Could not create composition video track.")
        }

        try compositionVideoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: sourceVideoTrack,
            at: .zero
        )

        if let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(
               withMediaType: .audio,
               preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            try compositionAudioTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
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

        let videoLayer = CALayer()
        videoLayer.frame = parentLayer.bounds
        parentLayer.addSublayer(videoLayer)

        let effectiveStyle = resolvedStyle(style)
        addCaptionLayers(to: parentLayer, segments: segments, style: effectiveStyle, renderSize: renderSize)

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
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
                layer.beginTime = segment.startTime
                layer.duration = max(0.05, segment.endTime - segment.startTime)
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
            let dimLayer = makeTextLayer(text: segment.text, style: style, renderSize: renderSize)
            dimLayer.opacity = 0.45
            dimLayer.beginTime = segment.startTime + Double(index) * wordDuration
            dimLayer.duration = wordDuration
            parent.addSublayer(dimLayer)

            let highlightLayer = makeTextLayer(text: word, style: style, renderSize: renderSize)
            highlightLayer.foregroundColor = NSColor.systemYellow.cgColor
            highlightLayer.beginTime = segment.startTime + Double(index) * wordDuration
            highlightLayer.duration = wordDuration
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
            let layer = makeTextLayer(text: word.uppercased(), style: style, renderSize: renderSize)
            layer.beginTime = segment.startTime + Double(index) * wordDuration
            layer.duration = wordDuration
            parent.addSublayer(layer)
        }
    }

    private func makeTextLayer(text: String, style: CaptionStyleConfig, renderSize: CGSize) -> CATextLayer {
        let scale = renderSize.height / 1080
        let fontSize = style.fontSize * scale
        let font = NSFont(name: style.fontName, size: fontSize) ?? NSFont.boldSystemFont(ofSize: fontSize)

        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.font = font
        textLayer.fontSize = font.pointSize
        textLayer.foregroundColor = style.nsTextColor.cgColor
        textLayer.alignmentMode = .center
        textLayer.isWrapped = true
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2

        let maxWidth = renderSize.width * 0.88
        let textHeight = fontSize * 1.35
        let padding: CGFloat = style.showsBackground ? 14 * scale : 0
        let boxHeight = textHeight + padding * 2

        let y = style.captionOriginY(renderHeight: renderSize.height, boxHeight: boxHeight)
        textLayer.frame = CGRect(
            x: (renderSize.width - maxWidth) / 2,
            y: y,
            width: maxWidth,
            height: boxHeight
        )

        if style.showsBackground, let background = style.nsBackgroundColor {
            let backgroundLayer = CALayer()
            backgroundLayer.backgroundColor = background.cgColor
            backgroundLayer.cornerRadius = 8 * scale
            backgroundLayer.frame = textLayer.frame
            backgroundLayer.beginTime = AVCoreAnimationBeginTimeAtZero
            textLayer.backgroundColor = background.cgColor
            textLayer.cornerRadius = 8 * scale
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
