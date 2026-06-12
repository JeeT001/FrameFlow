//
//  InstagramReelsGuideOverlayView.swift
//  FrameFlow
//

import SwiftUI

/// iPhone-style Instagram Reels mock chrome for Layout Picker preview only.
struct InstagramReelsGuideOverlayView: View {
    let canvasSize: CGSize

    private var w: CGFloat { canvasSize.width }
    private var h: CGFloat { canvasSize.height }

    private func ptW(_ pt: CGFloat) -> CGFloat {
        InstagramReelsLayoutMetrics.ptWidth(pt, canvasWidth: w)
    }

    private func ptH(_ pt: CGFloat) -> CGFloat {
        InstagramReelsLayoutMetrics.ptHeight(pt, canvasHeight: h)
    }

    private var navBarHeight: CGFloat {
        InstagramReelsLayoutMetrics.navBarHeight(for: h)
    }

    var body: some View {
        ZStack {
            bottomLeftInfo
            rightActionColumn
            bottomNavigationBar
        }
        .frame(width: w, height: h)
        .allowsHitTesting(false)
    }

    // MARK: - Bottom navigation

    private var bottomNavigationBar: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            HStack(spacing: 0) {
                navIcon("house", isActive: false)
                navIcon("film", isActive: true)
                navIcon("plus.square", isActive: false, isCreate: true)
                navIcon("magnifyingglass", isActive: false)
                navIcon("person.circle", isActive: false)
            }
            .frame(height: navBarHeight)
            .frame(maxWidth: .infinity)
            .background(Color.black)
        }
    }

    private func navIcon(_ systemName: String, isActive: Bool, isCreate: Bool = false) -> some View {
        Image(systemName: systemName)
            .font(
                .system(
                    size: ptW(isCreate ? InstagramReelsLayoutMetrics.navCreateIconSize : InstagramReelsLayoutMetrics.navIconSize),
                    weight: isActive ? .semibold : .regular
                )
            )
            .symbolVariant(isActive ? .fill : .none)
            .foregroundStyle(.white.opacity(isActive ? 1 : 0.85))
            .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom-left profile + caption

    private var bottomLeftInfo: some View {
        VStack(alignment: .leading, spacing: ptH(InstagramReelsLayoutMetrics.leftStackItemSpacing)) {
            profileRow
            captionText
        }
        .frame(maxWidth: w * InstagramReelsLayoutMetrics.leftStackMaxWidthFraction, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.leading, ptW(InstagramReelsLayoutMetrics.leftInset))
        .padding(.trailing, w * InstagramReelsLayoutMetrics.rightColumnReserveWidthFraction)
        .padding(.bottom, ptH(InstagramReelsLayoutMetrics.leftStackBottomOffset))
    }

    private var profileRow: some View {
        HStack(spacing: ptW(8)) {
            profileAvatar

            Text("fernandaagne…")
                .font(.system(size: ptW(InstagramReelsLayoutMetrics.usernameFontSize), weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: ptW(InstagramReelsLayoutMetrics.verifiedBadgeSize)))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)

            followButton

            Spacer(minLength: 0)
        }
        .shadow(color: .black.opacity(0.55), radius: 2, x: 0, y: 1)
    }

    private var profileAvatar: some View {
        let size = ptW(InstagramReelsLayoutMetrics.avatarSize)
        let ringWidth = ptW(InstagramReelsLayoutMetrics.avatarRingWidth)
        let outerPad = ptW(InstagramReelsLayoutMetrics.avatarRingOuterPadding)

        return Circle()
            .strokeBorder(
                AngularGradient(
                    colors: [
                        Color(red: 0.98, green: 0.45, blue: 0.25),
                        Color(red: 0.85, green: 0.15, blue: 0.55),
                        Color(red: 0.55, green: 0.25, blue: 0.95),
                        Color(red: 0.98, green: 0.45, blue: 0.25)
                    ],
                    center: .center
                ),
                lineWidth: ringWidth
            )
            .frame(width: size + outerPad * 2, height: size + outerPad * 2)
            .overlay {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: ptW(14)))
                            .foregroundStyle(.white.opacity(0.9))
                    }
            }
    }

    private var followButton: some View {
        Text("Follow")
            .font(.system(size: ptW(InstagramReelsLayoutMetrics.followFontSize), weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, ptW(InstagramReelsLayoutMetrics.followButtonHPadding))
            .padding(.vertical, ptH(InstagramReelsLayoutMetrics.followButtonVPadding))
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.85), lineWidth: 1)
            }
    }

    private var captionText: some View {
        Text("Some dresses were made for …")
            .font(.system(size: ptW(InstagramReelsLayoutMetrics.captionFontSize), weight: .regular))
            .foregroundStyle(.white)
            .lineLimit(2)
            .shadow(color: .black.opacity(0.55), radius: 2, x: 0, y: 1)
    }

    // MARK: - Right action column

    private var rightActionColumn: some View {
        VStack(spacing: ptH(InstagramReelsLayoutMetrics.actionSpacing)) {
            actionItem(icon: "heart", label: "3,555")
            actionItem(icon: "bubble.right", label: "26")
            actionItem(icon: "paperplane", label: "24")
            actionItem(icon: "play.rectangle.on.rectangle", label: "213")
            moreButton
            audioThumbnail
        }
        .padding(.trailing, ptW(InstagramReelsLayoutMetrics.rightColumnTrailing))
        .padding(.bottom, ptH(InstagramReelsLayoutMetrics.rightColumnBottomOffset))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }

    private var moreButton: some View {
        Image(systemName: "ellipsis")
            .font(.system(size: ptW(InstagramReelsLayoutMetrics.moreIconSize), weight: .semibold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
    }

    private var audioThumbnail: some View {
        let size = ptW(InstagramReelsLayoutMetrics.audioThumbSize)
        let corner = ptW(InstagramReelsLayoutMetrics.audioThumbCornerRadius)

        return RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Color.white.opacity(0.22))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: ptW(14)))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(.white.opacity(0.45), lineWidth: 1)
            }
    }

    private func actionItem(icon: String, label: String) -> some View {
        VStack(spacing: ptH(InstagramReelsLayoutMetrics.actionLabelGap)) {
            Image(systemName: icon)
                .font(.system(size: ptW(InstagramReelsLayoutMetrics.actionIconSize), weight: .regular))
            Text(label)
                .font(.system(size: ptW(InstagramReelsLayoutMetrics.actionCountSize), weight: .semibold))
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Previews

private struct InstagramReelsGuidePreviewBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.55, green: 0.35, blue: 0.25), Color(red: 0.25, green: 0.18, blue: 0.15)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview("Instagram Reels — 720×1280 (recording canvas)") {
    InstagramReelsGuideOverlayView(canvasSize: CGSize(width: 720, height: 1280))
        .background(InstagramReelsGuidePreviewBackground())
}

#Preview("Instagram Reels — 414×896 (iPhone 11)") {
    InstagramReelsGuideOverlayView(canvasSize: CGSize(width: 414, height: 896))
        .background(InstagramReelsGuidePreviewBackground())
}
