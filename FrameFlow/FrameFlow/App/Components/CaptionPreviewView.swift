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
                        highlightedWord: highlightedWord,
                        showsPlacementChrome: showsPlacementChrome
                    )
                    .offset(y: style.swiftUIVerticalOffset(containerHeight: geometry.size.height))
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
        PreviewTransportBar(
            currentTime: $currentTime,
            duration: duration,
            isPlaying: isPreviewPlaying,
            onSkipBack: { onSkipBack?() ?? onSeek(0) },
            onSlowMotion: { onSlowMotion?() },
            onPlayPause: { onTogglePlayback?() },
            onStop: { onStop?() },
            onSetInPoint: { onSetInPoint?() },
            onSetOutPoint: { onSetOutPoint?() },
            onSnapshot: { onSnapshot?() },
            onFullscreen: { onFullscreen?() }
        )
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
    var highlightedWord: String?
    var showsPlacementChrome: Bool = false

    var body: some View {
        VStack {
            overlayContent
                .padding(.horizontal, 16)
                .padding(.vertical, style.showsBackground ? 8 : 4)
                .background {
                    if let background = style.swiftUIBackgroundColor {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(background.opacity(0.85))
                    }
                }
                .overlay {
                    if showsPlacementChrome {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                AppColors.primary.opacity(0.85),
                                style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                            )
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: verticalAlignment)
        .padding(edgeInsets)
    }

    @ViewBuilder
    private var overlayContent: some View {
        switch style.preset {
        case .tiktokBold:
            Text(text)
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(style.swiftUITextColor)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
        case .highlightedWord:
            highlightedTextView
        case .minimal:
            Text(text)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.8), radius: 2, y: 1)
        case .custom:
            Text(text)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(AppColors.primary, lineWidth: 2)
                )
        default:
            Text(text)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var highlightedTextView: some View {
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
            .font(.system(size: 20, weight: .semibold))
            .multilineTextAlignment(.center)
        } else {
            Text(text)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var verticalAlignment: Alignment {
        switch style.verticalPosition {
        case .top: .top
        case .middle: .center
        case .bottom: .bottom
        }
    }

    private var edgeInsets: EdgeInsets {
        switch style.verticalPosition {
        case .top:
            return EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0)
        case .middle:
            return EdgeInsets()
        case .bottom:
            return EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)
        }
    }
}
