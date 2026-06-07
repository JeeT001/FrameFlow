//
//  CaptionPreviewView.swift
//  FrameFlow
//

import AVKit
import SwiftUI

struct CaptionPreviewView: View {
    let player: AVPlayer
    @Binding var currentTime: Double
    let duration: Double
    let style: CaptionStyleConfig
    let displayText: String?
    let highlightedWord: String?
    let isCaptionPlacementEditable: Bool
    let onSeek: (Double) -> Void
    let onCaptionVerticalOffsetChange: ((Double) -> Void)?

    @State private var dragStartOffset: Double?

    init(
        player: AVPlayer,
        currentTime: Binding<Double>,
        duration: Double,
        style: CaptionStyleConfig,
        displayText: String?,
        highlightedWord: String?,
        isCaptionPlacementEditable: Bool = false,
        onSeek: @escaping (Double) -> Void,
        onCaptionVerticalOffsetChange: ((Double) -> Void)? = nil
    ) {
        self.player = player
        self._currentTime = currentTime
        self.duration = duration
        self.style = style
        self.displayText = displayText
        self.highlightedWord = highlightedWord
        self.isCaptionPlacementEditable = isCaptionPlacementEditable
        self.onSeek = onSeek
        self.onCaptionVerticalOffsetChange = onCaptionVerticalOffsetChange
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                VideoPlayer(player: player)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if let displayText {
                    GeometryReader { geometry in
                        CaptionOverlayView(
                            text: displayText,
                            style: style,
                            highlightedWord: highlightedWord,
                            showsPlacementChrome: isCaptionPlacementEditable
                        )
                        .offset(y: style.swiftUIVerticalOffset(containerHeight: geometry.size.height))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .contentShape(Rectangle())
                        .gesture(placementDragGesture(containerHeight: geometry.size.height))
                    }
                    .allowsHitTesting(isCaptionPlacementEditable || displayText != nil)
                }
            }
            .background(Color.black, in: RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 12) {
                Text(formatTime(currentTime))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 44, alignment: .leading)

                Slider(
                    value: Binding(
                        get: { currentTime },
                        set: { newValue in
                            currentTime = newValue
                            onSeek(newValue)
                        }
                    ),
                    in: 0...max(duration, 0.1)
                )

                Text(formatTime(duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 44, alignment: .trailing)
            }
        }
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

    private func formatTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
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
