//
//  YouTubeShortsGuideOverlayView.swift
//  FrameFlow
//

import SwiftUI

/// iPhone-style YouTube Shorts mock chrome for Layout Picker preview only.
struct YouTubeShortsGuideOverlayView: View {
    let canvasSize: CGSize

    private var w: CGFloat { canvasSize.width }
    private var h: CGFloat { canvasSize.height }

    private func ptW(_ pt: CGFloat) -> CGFloat {
        YouTubeShortsLayoutMetrics.ptWidth(pt, canvasWidth: w)
    }

    private func ptH(_ pt: CGFloat) -> CGFloat {
        YouTubeShortsLayoutMetrics.ptHeight(pt, canvasHeight: h)
    }

    private var navBarHeight: CGFloat {
        YouTubeShortsLayoutMetrics.navBarHeight(for: h)
    }

    var body: some View {
        ZStack {
            bottomLeftStack
            rightActionColumn
            bottomChrome
        }
        .frame(width: w, height: h)
        .allowsHitTesting(false)
    }

    // MARK: - Bottom chrome (progress + nav)

    private var bottomChrome: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            progressBar

            bottomNavigationBar
        }
    }

    private var progressBar: some View {
        let barHeight = max(ptH(YouTubeShortsLayoutMetrics.progressBarHeight), 1.5)
        let playheadSize = ptW(YouTubeShortsLayoutMetrics.progressPlayheadSize)
        let filledWidth = w * YouTubeShortsLayoutMetrics.progressFilledWidthFraction

        return ZStack(alignment: .leading) {
            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(height: barHeight)

            Circle()
                .fill(Color.red)
                .frame(width: playheadSize, height: playheadSize)
                .offset(x: w * YouTubeShortsLayoutMetrics.progressPlayheadXFraction)

            Rectangle()
                .fill(Color.red)
                .frame(width: filledWidth, height: barHeight)
        }
        .frame(height: barHeight)
    }

    private var bottomNavigationBar: some View {
        HStack(spacing: 0) {
            navTab(icon: "house.fill", label: "Home", isActive: false)
            navTab(icon: "play.rectangle.fill", label: "Shorts", isActive: true)
            navTab(icon: "plus.circle.fill", label: "", isActive: false, isCreate: true)
            navTab(icon: "rectangle.stack.fill", label: "Subscriptions", isActive: false, showsBadge: true)
            navTab(icon: "play.square.stack.fill", label: "Library", isActive: false)
        }
        .frame(height: navBarHeight)
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }

    private func navTab(
        icon: String,
        label: String,
        isActive: Bool,
        isCreate: Bool = false,
        showsBadge: Bool = false
    ) -> some View {
        VStack(spacing: ptH(2)) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(
                        .system(
                            size: ptW(isCreate ? YouTubeShortsLayoutMetrics.navCreateIconSize : YouTubeShortsLayoutMetrics.navIconSize),
                            weight: isActive ? .bold : .regular
                        )
                    )
                    .foregroundStyle(isActive ? .white : .white.opacity(0.72))

                if showsBadge {
                    Circle()
                        .fill(Color.red)
                        .frame(
                            width: ptW(YouTubeShortsLayoutMetrics.navBadgeSize),
                            height: ptW(YouTubeShortsLayoutMetrics.navBadgeSize)
                        )
                        .offset(x: ptW(4), y: ptH(-2))
                }
            }
            .frame(height: ptW(YouTubeShortsLayoutMetrics.navIconSize))

            if !label.isEmpty {
                Text(label)
                    .font(.system(size: ptW(YouTubeShortsLayoutMetrics.navLabelSize), weight: isActive ? .bold : .medium))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom-left metadata stack

    private var bottomLeftStack: some View {
        VStack(alignment: .leading, spacing: ptH(YouTubeShortsLayoutMetrics.leftStackItemSpacing)) {
            useThisSoundPill
            channelRow
            descriptionText
            songPill
        }
        .frame(maxWidth: w * YouTubeShortsLayoutMetrics.leftStackMaxWidthFraction, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.leading, ptW(YouTubeShortsLayoutMetrics.leftInset))
        .padding(.trailing, w * YouTubeShortsLayoutMetrics.rightColumnReserveWidthFraction)
        .padding(.bottom, ptH(YouTubeShortsLayoutMetrics.leftStackBottomOffset))
    }

    private var useThisSoundPill: some View {
        HStack(spacing: ptW(6)) {
            Image(systemName: "camera.fill")
                .font(.system(size: ptW(YouTubeShortsLayoutMetrics.useThisSoundFontSize), weight: .semibold))
            Text("Use this sound")
                .font(.system(size: ptW(YouTubeShortsLayoutMetrics.useThisSoundFontSize), weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, ptW(12))
        .padding(.vertical, ptH(6))
        .background(.black.opacity(0.55), in: Capsule())
    }

    private var channelRow: some View {
        HStack(spacing: ptW(8)) {
            Circle()
                .fill(.white.opacity(0.22))
                .frame(width: ptW(YouTubeShortsLayoutMetrics.avatarSize), height: ptW(YouTubeShortsLayoutMetrics.avatarSize))
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: ptW(12)))
                        .foregroundStyle(.white.opacity(0.9))
                }

            Text("@channelname")
                .font(.system(size: ptW(YouTubeShortsLayoutMetrics.channelFontSize), weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text("Subscribe")
                .font(.system(size: ptW(YouTubeShortsLayoutMetrics.channelFontSize), weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
    }

    private var descriptionText: some View {
        Text("Caption text… #hashtag…")
            .font(.system(size: ptW(YouTubeShortsLayoutMetrics.descriptionFontSize), weight: .medium))
            .foregroundStyle(.white)
            .lineLimit(2)
            .shadow(color: .black.opacity(0.55), radius: 2, x: 0, y: 1)
    }

    private var songPill: some View {
        HStack(spacing: ptW(6)) {
            Image(systemName: "music.note")
                .font(.system(size: ptW(YouTubeShortsLayoutMetrics.songFontSize), weight: .semibold))
            Text("Song title · Artist name")
                .font(.system(size: ptW(YouTubeShortsLayoutMetrics.songFontSize), weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, ptW(10))
        .padding(.vertical, ptH(5))
        .background(.black.opacity(0.55), in: Capsule())
    }

    // MARK: - Right action column

    private var rightActionColumn: some View {
        VStack(spacing: ptH(YouTubeShortsLayoutMetrics.actionSpacing)) {
            actionItem(icon: "hand.thumbsup", label: "Like")
            actionItem(icon: "hand.thumbsdown", label: "Dislike")
            actionItem(icon: "bubble.right", label: "11")
            actionItem(icon: "arrowshape.turn.up.right", label: "Share")
            actionItem(icon: "arrow.triangle.2.circlepath", label: "1.5m")

            musicThumbnail
        }
        .padding(.trailing, ptW(YouTubeShortsLayoutMetrics.rightColumnTrailing))
        .padding(.bottom, ptH(YouTubeShortsLayoutMetrics.rightColumnBottomOffset))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }

    private var musicThumbnail: some View {
        let size = ptW(YouTubeShortsLayoutMetrics.musicThumbSize)
        let corner = ptW(YouTubeShortsLayoutMetrics.musicThumbCornerRadius)

        return RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Color.gray.opacity(0.55))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: ptW(14)))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1)
            }
    }

    private func actionItem(icon: String, label: String) -> some View {
        VStack(spacing: ptH(YouTubeShortsLayoutMetrics.actionLabelGap)) {
            Image(systemName: icon)
                .font(.system(size: ptW(YouTubeShortsLayoutMetrics.actionIconSize), weight: .regular))
            Text(label)
                .font(.system(size: ptW(YouTubeShortsLayoutMetrics.actionLabelSize), weight: .medium))
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Previews

private struct YouTubeShortsGuidePreviewBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.blue.opacity(0.4), .purple.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview("YouTube Shorts — 720×1280 (recording canvas)") {
    YouTubeShortsGuideOverlayView(canvasSize: CGSize(width: 720, height: 1280))
        .background(YouTubeShortsGuidePreviewBackground())
}

#Preview("YouTube Shorts — 414×896 (iPhone 11)") {
    YouTubeShortsGuideOverlayView(canvasSize: CGSize(width: 414, height: 896))
        .background(YouTubeShortsGuidePreviewBackground())
}
