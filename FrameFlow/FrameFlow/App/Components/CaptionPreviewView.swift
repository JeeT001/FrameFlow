//
//  CaptionPreviewView.swift
//  FrameFlow
//

import AVKit
import SwiftUI

struct CaptionPreviewView<PreviewOverlay: View>: View {
    let player: AVPlayer
    @Binding var currentTime: Double
    let duration: Double
    var previewAspectRatio: CGFloat
    var videoEndSeconds: Double?
    var isPlayheadPastVideo: Bool = false
    var isPreviewPlaying: Bool = false
    let style: CaptionStyleConfig
    let displayText: String?
    let highlightedWord: String?
    let isCaptionPlacementEditable: Bool
    var showsPlacementChrome: Bool = false
    let onSeek: (Double) -> Void
    var onTogglePlayback: (() -> Void)?
    let onCaptionVerticalOffsetChange: ((Double) -> Void)?
    var onSkipBack: (() -> Void)?
    var onSlowMotion: (() -> Void)?
    var onStop: (() -> Void)?
    var onSetInPoint: (() -> Void)?
    var onSetOutPoint: (() -> Void)?
    var onSnapshot: (() -> Void)?
    var onFullscreen: (() -> Void)?
    @ViewBuilder var previewOverlay: () -> PreviewOverlay

    @State private var dragStartOffset: Double?

    init(
        player: AVPlayer,
        currentTime: Binding<Double>,
        duration: Double,
        previewAspectRatio: CGFloat = 16.0 / 9.0,
        videoEndSeconds: Double? = nil,
        isPlayheadPastVideo: Bool = false,
        isPreviewPlaying: Bool = false,
        style: CaptionStyleConfig,
        displayText: String?,
        highlightedWord: String?,
        isCaptionPlacementEditable: Bool = false,
        showsPlacementChrome: Bool = false,
        onSeek: @escaping (Double) -> Void,
        onTogglePlayback: (() -> Void)? = nil,
        onCaptionVerticalOffsetChange: ((Double) -> Void)? = nil,
        onSkipBack: (() -> Void)? = nil,
        onSlowMotion: (() -> Void)? = nil,
        onStop: (() -> Void)? = nil,
        onSetInPoint: (() -> Void)? = nil,
        onSetOutPoint: (() -> Void)? = nil,
        onSnapshot: (() -> Void)? = nil,
        onFullscreen: (() -> Void)? = nil,
        @ViewBuilder previewOverlay: @escaping () -> PreviewOverlay
    ) {
        self.player = player
        self._currentTime = currentTime
        self.duration = duration
        self.previewAspectRatio = previewAspectRatio
        self.videoEndSeconds = videoEndSeconds
        self.isPlayheadPastVideo = isPlayheadPastVideo
        self.isPreviewPlaying = isPreviewPlaying
        self.style = style
        self.displayText = displayText
        self.highlightedWord = highlightedWord
        self.isCaptionPlacementEditable = isCaptionPlacementEditable
        self.showsPlacementChrome = showsPlacementChrome
        self.onSeek = onSeek
        self.onTogglePlayback = onTogglePlayback
        self.onCaptionVerticalOffsetChange = onCaptionVerticalOffsetChange
        self.onSkipBack = onSkipBack
        self.onSlowMotion = onSlowMotion
        self.onStop = onStop
        self.onSetInPoint = onSetInPoint
        self.onSetOutPoint = onSetOutPoint
        self.onSnapshot = onSnapshot
        self.onFullscreen = onFullscreen
        self.previewOverlay = previewOverlay
    }

    var body: some View {
        VStack(spacing: 10) {
            videoCanvas
            timelineScrubber
        }
        .background(Color.black)
    }

    private var videoCanvas: some View {
        ZStack {
            Color.black

            EditorChromelessPlayer(player: player)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isPlayheadPastVideo {
                audioOnlyOverlay
            }

            if let displayText {
                GeometryReader { geometry in
                    CaptionOverlayView(
                        text: displayText,
                        style: style,
                        containerSize: geometry.size,
                        highlightedWord: highlightedWord,
                        showsPlacementChrome: showsPlacementChrome
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .gesture(placementDragGesture(containerHeight: geometry.size.height))
                }
                .allowsHitTesting(isCaptionPlacementEditable)
            }

            previewOverlay()
        }
        .aspectRatio(previewAspectRatio, contentMode: .fit)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture {
            onTogglePlayback?()
        }
    }

    private var audioOnlyOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
            VStack(spacing: 8) {
                Image(systemName: isPreviewPlaying ? "waveform" : "music.note")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
                Text(isPreviewPlaying ? "Playing imported audio" : "Video ended")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Tap preview or press Space to play")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding()
        }
        .allowsHitTesting(false)
    }

    private var timelineScrubber: some View {
        HStack(spacing: 12) {
            Button {
                onTogglePlayback?()
            } label: {
                Image(systemName: isPreviewPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .help(isPreviewPlaying ? "Pause" : "Play")

            Text(formatTimeDetailed(currentTime))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 52, alignment: .leading)

            Slider(value: $currentTime, in: 0...max(duration, 0.01))
                .tint(.white.opacity(0.85))

            Text(formatTimeDetailed(duration))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 52, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
    }

    private func placementDragGesture(containerHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard isCaptionPlacementEditable else { return }
                if dragStartOffset == nil {
                    dragStartOffset = style.clampedVerticalOffset
                }
                let normalizedDelta = -Double(value.translation.height / containerHeight)
                let newOffset = (dragStartOffset ?? 0) + normalizedDelta
                let clamped = min(
                    max(newOffset, CaptionStyleConfig.verticalOffsetRange.lowerBound),
                    CaptionStyleConfig.verticalOffsetRange.upperBound
                )
                onCaptionVerticalOffsetChange?(clamped)
            }
            .onEnded { _ in
                dragStartOffset = nil
            }
    }

    private func formatTimeDetailed(_ seconds: Double) -> String {
        let total = max(0, seconds)
        let minutes = Int(total) / 60
        let secs = Int(total) % 60
        let tenths = Int((total.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, secs, tenths)
    }
}

extension CaptionPreviewView where PreviewOverlay == EmptyView {
    init(
        player: AVPlayer,
        currentTime: Binding<Double>,
        duration: Double,
        previewAspectRatio: CGFloat = 16.0 / 9.0,
        videoEndSeconds: Double? = nil,
        isPlayheadPastVideo: Bool = false,
        isPreviewPlaying: Bool = false,
        style: CaptionStyleConfig,
        displayText: String?,
        highlightedWord: String?,
        isCaptionPlacementEditable: Bool = false,
        showsPlacementChrome: Bool = false,
        onSeek: @escaping (Double) -> Void,
        onTogglePlayback: (() -> Void)? = nil,
        onCaptionVerticalOffsetChange: ((Double) -> Void)? = nil,
        onSkipBack: (() -> Void)? = nil,
        onSlowMotion: (() -> Void)? = nil,
        onStop: (() -> Void)? = nil,
        onSetInPoint: (() -> Void)? = nil,
        onSetOutPoint: (() -> Void)? = nil,
        onSnapshot: (() -> Void)? = nil,
        onFullscreen: (() -> Void)? = nil
    ) {
        self.init(
            player: player,
            currentTime: currentTime,
            duration: duration,
            previewAspectRatio: previewAspectRatio,
            videoEndSeconds: videoEndSeconds,
            isPlayheadPastVideo: isPlayheadPastVideo,
            isPreviewPlaying: isPreviewPlaying,
            style: style,
            displayText: displayText,
            highlightedWord: highlightedWord,
            isCaptionPlacementEditable: isCaptionPlacementEditable,
            showsPlacementChrome: showsPlacementChrome,
            onSeek: onSeek,
            onTogglePlayback: onTogglePlayback,
            onCaptionVerticalOffsetChange: onCaptionVerticalOffsetChange,
            onSkipBack: onSkipBack,
            onSlowMotion: onSlowMotion,
            onStop: onStop,
            onSetInPoint: onSetInPoint,
            onSetOutPoint: onSetOutPoint,
            onSnapshot: onSnapshot,
            onFullscreen: onFullscreen,
            previewOverlay: { EmptyView() }
        )
    }
}

struct CaptionOverlayView: View {
    let text: String
    let style: CaptionStyleConfig
    let containerSize: CGSize
    var highlightedWord: String?
    var showsPlacementChrome: Bool = false

    var body: some View {
        let frame = CaptionLayoutMath.captionFrame(style: style, containerSize: containerSize)
        let fontSize = CaptionLayoutMath.scaledFontSize(style: style, containerHeight: containerSize.height)
        let cornerRadius = CaptionLayoutMath.cornerRadius(style: style, containerHeight: containerSize.height)
        let innerPadding = CaptionLayoutMath.backgroundPadding(containerHeight: containerSize.height)

        overlayContent(fontSize: fontSize)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, style.showsBackground ? innerPadding : innerPadding * 0.3)
            .padding(.vertical, style.showsBackground ? innerPadding * 0.6 : innerPadding * 0.25)
            .background {
                if let background = style.swiftUIBackgroundColor {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(background.opacity(0.85))
                }
            }
            .overlay {
                if showsPlacementChrome {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            AppColors.primary.opacity(0.85),
                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                        )
                }
            }
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
    }

    @ViewBuilder
    private func overlayContent(fontSize: CGFloat) -> some View {
        switch style.preset {
        case .tiktokBold:
            Text(text)
                .font(.system(size: fontSize * CaptionLayoutMath.exportFontMultiplier(for: style.preset), weight: .heavy))
                .foregroundStyle(style.swiftUITextColor)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
        case .highlightedWord:
            highlightedTextView(fontSize: fontSize * CaptionLayoutMath.exportFontMultiplier(for: style.preset))
        case .minimal:
            Text(text)
                .font(.system(size: fontSize * CaptionLayoutMath.exportFontMultiplier(for: style.preset), weight: .regular))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.8), radius: 2, y: 1)
        case .custom:
            Text(text)
                .font(.system(size: fontSize * CaptionLayoutMath.exportFontMultiplier(for: style.preset), weight: .semibold))
                .foregroundStyle(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppColors.primary, lineWidth: 2)
                )
        default:
            Text(text)
                .font(.system(size: fontSize * CaptionLayoutMath.exportFontMultiplier(for: style.preset), weight: .bold))
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private func highlightedTextView(fontSize: CGFloat) -> some View {
        if let highlightedWord, text.contains(highlightedWord) {
            let parts = text.components(separatedBy: highlightedWord)
            HStack(spacing: 4) {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    if !part.isEmpty {
                        Text(part)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    if index < parts.count - 1 {
                        Text(highlightedWord)
                            .foregroundStyle(.yellow)
                            .fontWeight(.bold)
                    }
                }
            }
            .font(.system(size: fontSize, weight: .semibold))
        } else {
            Text(text)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}
