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
        let videoTrackRange = try await sourceVideoTrack.load(.timeRange)
        let videoTrackSeconds = CMTimeGetSeconds(videoTrackRange.duration)
        let leadingGap = max(0, leadingVideoGapSeconds)
        let exportSeconds = max(0.05, videoTrackSeconds - leadingGap)
        let exportDuration = CMTime(seconds: exportSeconds, preferredTimescale: 600)

        let timedSegments = clampSegments(cleaned, exportSeconds: exportSeconds)
        guard !timedSegments.isEmpty else {
            throw CaptionRendererError.exportFailed("No caption segments within video duration.")
        }

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

        #if DEBUG
        print(
            "[CaptionRenderer] burn-in renderSize=\(Int(renderSize.width))x\(Int(renderSize.height)) " +
            "segments=\(timedSegments.count) leadingGap=\(String(format: "%.3f", leadingGap))s " +
            "exportSeconds=\(String(format: "%.2f", exportSeconds))s"
        )
        #endif

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
        addCaptionLayers(to: parentLayer, segments: timedSegments, style: effectiveStyle, renderSize: renderSize)

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

    private func clampSegments(_ segments: [CaptionSegment], exportSeconds: Double) -> [CaptionSegment] {
        segments.compactMap { segment in
            guard segment.startTime < exportSeconds - 0.01 else { return nil }
            var adjusted = segment
            adjusted.startTime = max(0, min(segment.startTime, exportSeconds - 0.05))
            adjusted.endTime = max(
                adjusted.startTime + 0.05,
                min(segment.endTime, exportSeconds)
            )
            return adjusted
        }
    }

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
        layer.beginTime = timelineTime(startTime)
        layer.duration = segmentDuration
        layer.opacity = visibleOpacity
        layer.isHidden = false
        layer.zPosition = 10
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
        for (segmentIndex, segment) in segments.enumerated() {
            switch style.preset {
            case .tiktokBold:
                addWordLayers(
                    for: segment,
                    style: style,
                    renderSize: renderSize,
                    parent: parentLayer,
                    segmentIndex: segmentIndex
                )
            case .highlightedWord:
                addHighlightedWordLayers(
                    for: segment,
                    style: style,
                    renderSize: renderSize,
                    parent: parentLayer,
                    segmentIndex: segmentIndex
                )
            default:
                let layer = makeCaptionExportLayer(
                    text: segment.text,
                    style: style,
                    renderSize: renderSize
                )
                configureClassicSegmentLayer(layer, segment: segment, segmentIndex: segmentIndex)
                parentLayer.addSublayer(layer)
            }
        }
    }

    /// Classic / Minimal / Custom segment timing — first segment needs offline-export-safe window anchoring.
    private func configureClassicSegmentLayer(
        _ layer: CALayer,
        segment: CaptionSegment,
        segmentIndex: Int
    ) {
        let adjustedStart = adjustedSegmentStart(segmentIndex: segmentIndex, startTime: segment.startTime)
        let duration: Double
        if segmentIndex == 0 {
            duration = max(1.0 / 30.0, segment.endTime - adjustedStart)
        } else {
            duration = segment.endTime - segment.startTime
        }
        configureTimedLayer(layer, startTime: adjustedStart, duration: duration)

        #if DEBUG
        if segmentIndex == 0 {
            print(
                "[CaptionRenderer] Classic segment0 " +
                "rawStart=\(String(format: "%.2f", segment.startTime))s " +
                "adjustedStart=\(String(format: "%.3f", adjustedStart))s " +
                "dur=\(String(format: "%.2f", duration))s " +
                "end=\(String(format: "%.2f", segment.endTime))s"
            )
        }
        #endif
    }

    /// Nudge first segment off `AVCoreAnimationBeginTimeAtZero` for offline export visibility.
    private func adjustedSegmentStart(segmentIndex: Int, startTime: Double) -> Double {
        if segmentIndex == 0 {
            return startTime + 1.0 / 60.0
        }
        if startTime < 0.001 {
            return max(startTime, 1.0 / 60.0)
        }
        return startTime
    }

    private func addHighlightedWordLayers(
        for segment: CaptionSegment,
        style: CaptionStyleConfig,
        renderSize: CGSize,
        parent: CALayer,
        segmentIndex: Int
    ) {
        let windows = highlightedWordWindows(for: segment)
        guard !windows.isEmpty else { return }

        for (index, window) in windows.enumerated() {
            let layer = makeCaptionExportLayer(
                text: segment.text,
                style: style,
                renderSize: renderSize,
                highlightedWord: window.word
            )
            configureHighlightedWordLayer(
                layer,
                startTime: window.start,
                endTime: window.end,
                segmentIndex: segmentIndex,
                wordIndex: index,
                word: window.word
            )
            layer.zPosition = CGFloat(segmentIndex * 20 + index)
            parent.addSublayer(layer)
        }
    }

    /// Word windows aligned with `CaptionEditorViewModel.highlightedWord` (preview math, no nudge).
    private func highlightedWordWindows(
        for segment: CaptionSegment
    ) -> [(word: String, start: Double, end: Double)] {
        let words = segment.text.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return [] }

        let totalDuration = max(0.05, segment.endTime - segment.startTime)
        let count = Double(words.count)

        return words.enumerated().map { index, word in
            let start = segment.startTime + (Double(index) / count) * totalDuration
            let end = segment.startTime + (Double(index + 1) / count) * totalDuration
            return (word, start, end)
        }
    }

    /// Highlighted-only layer timing — preview-aligned start/end, fade-out at window end.
    private func configureHighlightedWordLayer(
        _ layer: CALayer,
        startTime: Double,
        endTime: Double,
        segmentIndex: Int,
        wordIndex: Int,
        word: String
    ) {
        let wordDuration = max(1.0 / 30.0, endTime - startTime)
        let begin = timelineTime(startTime)
        configureTimedLayer(layer, startTime: startTime, duration: wordDuration)

        let fadeLead = min(1.0 / 30.0, wordDuration * 0.12)
        let fadeStartFraction = max(0, (wordDuration - fadeLead) / wordDuration)

        let fadeOut = CAKeyframeAnimation(keyPath: "opacity")
        fadeOut.beginTime = begin
        fadeOut.duration = wordDuration
        fadeOut.values = [NSNumber(value: 1), NSNumber(value: 1), NSNumber(value: 0)]
        fadeOut.keyTimes = [0, NSNumber(value: fadeStartFraction), 1.0]
        fadeOut.fillMode = .forwards
        fadeOut.isRemovedOnCompletion = false
        layer.add(fadeOut, forKey: "highlightedWordFadeOut")

        #if DEBUG
        if segmentIndex == 0, wordIndex == 0 {
            print(
                "[CaptionRenderer] Highlighted seg0 word0 '\(word)' " +
                "start=\(String(format: "%.3f", startTime)) " +
                "end=\(String(format: "%.3f", endTime)) " +
                "fadeEnd=\(String(format: "%.3f", startTime + wordDuration))s"
            )
        }
        #endif
    }

    private func makeCaptionExportLayer(
        text: String,
        style: CaptionStyleConfig,
        renderSize: CGSize,
        highlightedWord: String? = nil
    ) -> CALayer {
        let container = CALayer()
        let boxFrame = CaptionLayoutMath.captionFrame(style: style, containerSize: renderSize)
        guard boxFrame.width > 1, boxFrame.height > 1 else {
            container.frame = CGRect(
                x: 0,
                y: renderSize.height * 0.75,
                width: renderSize.width,
                height: renderSize.height * 0.12
            )
            return container
        }
        container.frame = boxFrame
        container.masksToBounds = true

        let cornerRadius = CaptionLayoutMath.cornerRadius(style: style, containerHeight: renderSize.height)
        if style.showsBackground, let background = style.nsBackgroundColor {
            let backgroundLayer = CALayer()
            backgroundLayer.frame = container.bounds
            backgroundLayer.backgroundColor = background.withAlphaComponent(0.85).cgColor
            backgroundLayer.cornerRadius = cornerRadius
            container.addSublayer(backgroundLayer)
        }

        let padding = CaptionLayoutMath.textPaddingInsets(
            style: style,
            containerHeight: renderSize.height
        )
        let textFrame = CGRect(
            x: padding.horizontal,
            y: padding.vertical,
            width: boxFrame.width - padding.horizontal * 2,
            height: boxFrame.height - padding.vertical * 2
        )

        let textLayer = CATextLayer()
        textLayer.frame = textFrame
        textLayer.string = makeCaptionAttributedString(
            text: text,
            style: style,
            renderSize: renderSize,
            highlightedWord: highlightedWord
        )
        textLayer.alignmentMode = .center
        textLayer.isWrapped = true
        textLayer.truncationMode = .end
        textLayer.contentsScale = 2
        textLayer.masksToBounds = true
        container.addSublayer(textLayer)

        if style.preset == .custom {
            let layoutScale = CaptionLayoutMath.scale(for: renderSize.height)
            let borderLayer = CAShapeLayer()
            let borderRect = textFrame.insetBy(dx: -1, dy: -1)
            borderLayer.path = CGPath(
                roundedRect: borderRect,
                cornerWidth: 6 * layoutScale,
                cornerHeight: 6 * layoutScale,
                transform: nil
            )
            borderLayer.strokeColor = (NSColor(named: "appPrimary") ?? NSColor.systemBlue).cgColor
            borderLayer.fillColor = nil
            borderLayer.lineWidth = 2 * layoutScale
            container.addSublayer(borderLayer)
        }

        return container
    }

    private func makeCaptionAttributedString(
        text: String,
        style: CaptionStyleConfig,
        renderSize: CGSize,
        highlightedWord: String? = nil
    ) -> NSAttributedString {
        let fontSize = CaptionLayoutMath.exportFontSize(style: style, containerHeight: renderSize.height)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping

        if let highlightedWord, text.contains(highlightedWord) {
            return highlightedPhraseAttributedString(
                text: text,
                highlightedWord: highlightedWord,
                style: style,
                fontSize: fontSize,
                paragraph: paragraph
            )
        }

        let font = exportFont(style: style, fontSize: fontSize)
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: exportTextColor(style: style),
            .paragraphStyle: paragraph,
        ]
        if style.preset == .minimal {
            attributes[.shadow] = minimalTextShadow()
        }
        return NSAttributedString(string: text, attributes: attributes)
    }

    private func highlightedPhraseAttributedString(
        text: String,
        highlightedWord: String,
        style: CaptionStyleConfig,
        fontSize: CGFloat,
        paragraph: NSParagraphStyle
    ) -> NSAttributedString {
        let baseFont = exportFont(style: style, fontSize: fontSize)
        let boldFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
        let parts = text.components(separatedBy: highlightedWord)
        let result = NSMutableAttributedString()

        for (index, part) in parts.enumerated() {
            if !part.isEmpty {
                result.append(NSAttributedString(
                    string: part,
                    attributes: [
                        .font: baseFont,
                        .foregroundColor: NSColor.white.withAlphaComponent(0.55),
                        .paragraphStyle: paragraph,
                    ]
                ))
            }
            if index < parts.count - 1 {
                result.append(NSAttributedString(
                    string: highlightedWord,
                    attributes: [
                        .font: boldFont,
                        .foregroundColor: NSColor.systemYellow,
                        .paragraphStyle: paragraph,
                    ]
                ))
            }
        }
        return result
    }

    private func exportFont(style: CaptionStyleConfig, fontSize: CGFloat) -> NSFont {
        switch style.preset {
        case .minimal:
            return NSFont(name: style.fontName, size: fontSize)
                ?? NSFont.systemFont(ofSize: fontSize, weight: .regular)
        case .custom, .highlightedWord:
            return NSFont(name: style.fontName, size: fontSize)
                ?? NSFont.systemFont(ofSize: fontSize, weight: .semibold)
        default:
            return NSFont(name: style.fontName, size: fontSize)
                ?? NSFont.boldSystemFont(ofSize: fontSize)
        }
    }

    private func exportTextColor(style: CaptionStyleConfig) -> NSColor {
        switch style.preset {
        case .minimal, .custom, .classic, .highlightedWord:
            return .white
        default:
            return style.nsTextColor
        }
    }

    private func minimalTextShadow() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.8)
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.shadowBlurRadius = 2
        return shadow
    }

    private func addWordLayers(
        for segment: CaptionSegment,
        style: CaptionStyleConfig,
        renderSize: CGSize,
        parent: CALayer,
        segmentIndex: Int
    ) {
        let windows = tiktokWordWindows(for: segment)
        guard !windows.isEmpty else { return }
        let isFirstSegment = segmentIndex == 0

        #if DEBUG
        let windowSummary = windows.map { window in
            "\(window.word)@\(String(format: "%.2f", window.start))"
        }.joined(separator: ", ")
        print(
            "[CaptionRenderer] TikTok segment start=\(String(format: "%.2f", segment.startTime)) " +
            "words=\(windows.count) windows=[\(windowSummary)]"
        )
        #endif

        for (index, window) in windows.enumerated() {
            let layer = makeTextLayer(text: window.word, style: style, renderSize: renderSize)
            configureTikTokWordLayer(
                layer,
                startTime: window.start,
                duration: window.duration,
                wordIndex: index,
                segmentIndex: segmentIndex,
                nudgeFirstWord: isFirstSegment && index == 0
            )
            parent.addSublayer(layer)

            #if DEBUG
            if isFirstSegment, index == 0 {
                let nudged = window.start + 1.0 / 60.0
                let dur = max(1.0 / 30.0, window.duration)
                let fadeLead = min(1.0 / 30.0, dur * 0.12)
                print(
                    "[CaptionRenderer] TikTok firstSegment word0 '\(window.word)' " +
                    "layerBegin=\(String(format: "%.3f", nudged))s " +
                    "dur=\(String(format: "%.3f", dur))s " +
                    "fadeStart=\(String(format: "%.3f", dur - fadeLead))s"
                )
            }
            #endif
        }
    }

    /// Word windows aligned with `CaptionEditorViewModel.tiktokWord` (progress × word count).
    private func tiktokWordWindows(for segment: CaptionSegment) -> [(word: String, start: Double, duration: Double)] {
        let words = segment.text.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return [] }

        let totalDuration = max(0.05, segment.endTime - segment.startTime)
        let count = Double(words.count)
        let minWordDuration = 1.0 / 30.0

        return words.enumerated().map { index, word in
            let start = segment.startTime + (Double(index) / count) * totalDuration
            let end = segment.startTime + (Double(index + 1) / count) * totalDuration
            return (word.uppercased(), start, max(minWordDuration, end - start))
        }
    }

    /// One layer per word — static opacity (visible offline) + fade-out-only at window end.
    private func configureTikTokWordLayer(
        _ layer: CALayer,
        startTime: Double,
        duration: Double,
        wordIndex: Int,
        segmentIndex: Int,
        nudgeFirstWord: Bool
    ) {
        let wordDuration = max(1.0 / 30.0, duration)
        let adjustedStart: Double
        if nudgeFirstWord {
            adjustedStart = startTime + 1.0 / 60.0
        } else if startTime < 0.001 {
            adjustedStart = max(startTime, 1.0 / 60.0)
        } else {
            adjustedStart = startTime
        }

        let begin = timelineTime(adjustedStart)
        configureTimedLayer(layer, startTime: adjustedStart, duration: wordDuration)
        layer.zPosition = CGFloat(segmentIndex * 20 + wordIndex)

        let fadeLead = min(1.0 / 30.0, wordDuration * 0.12)
        let fadeStartFraction = max(0, (wordDuration - fadeLead) / wordDuration)

        // Absolute beginTime (matches layer) — relative beginTime=0 can hide early segments offline.
        let fadeOut = CAKeyframeAnimation(keyPath: "opacity")
        fadeOut.beginTime = begin
        fadeOut.duration = wordDuration
        fadeOut.values = [NSNumber(value: 1), NSNumber(value: 1), NSNumber(value: 0)]
        fadeOut.keyTimes = [0, NSNumber(value: fadeStartFraction), 1.0]
        fadeOut.fillMode = .forwards
        fadeOut.isRemovedOnCompletion = false
        layer.add(fadeOut, forKey: "tiktokWordFadeOut")
    }

    private func makeTextLayer(text: String, style: CaptionStyleConfig, renderSize: CGSize) -> CATextLayer {
        let fontSize = CaptionLayoutMath.scaledFontSize(style: style, containerHeight: renderSize.height)
        let font = NSFont(name: style.fontName, size: fontSize) ?? NSFont.boldSystemFont(ofSize: fontSize)

        let textLayer = CATextLayer()
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: style.nsTextColor,
        ]
        if style.showsBackground, let background = style.nsBackgroundColor {
            attributes[.backgroundColor] = background
        }
        textLayer.string = NSAttributedString(string: text, attributes: attributes)
        textLayer.fontSize = font.pointSize
        textLayer.alignmentMode = .center
        textLayer.isWrapped = true
        textLayer.contentsScale = 2
        textLayer.masksToBounds = false

        let frame = CaptionLayoutMath.captionFrame(style: style, containerSize: renderSize)
        guard frame.width > 1, frame.height > 1 else {
            textLayer.frame = CGRect(x: 0, y: renderSize.height * 0.75, width: renderSize.width, height: renderSize.height * 0.12)
            return textLayer
        }
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
