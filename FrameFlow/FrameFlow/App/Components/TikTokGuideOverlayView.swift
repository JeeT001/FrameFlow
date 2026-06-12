//
//  TikTokGuideOverlayView.swift
//  FrameFlow
//

import SwiftUI

/// iPhone-style TikTok For You mock chrome for Layout Picker preview only.
struct TikTokGuideOverlayView: View {
    let canvasSize: CGSize

    private var w: CGFloat { canvasSize.width }
    private var h: CGFloat { canvasSize.height }

    private func ptW(_ pt: CGFloat) -> CGFloat {
        TikTokLayoutMetrics.ptWidth(pt, canvasWidth: w)
    }

    private func ptH(_ pt: CGFloat) -> CGFloat {
        TikTokLayoutMetrics.ptHeight(pt, canvasHeight: h)
    }

    private var navBarHeight: CGFloat {
        TikTokLayoutMetrics.navBarHeight(for: h)
    }

    var body: some View {
        ZStack {
            topBar
            bottomLeftInfo
            rightActionColumn
            feedbackPills
            bottomNavigationBar
        }
        .frame(width: w, height: h)
        .allowsHitTesting(false)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 0) {
            Spacer(minLength: ptW(TikTokLayoutMetrics.searchIconSize + TikTokLayoutMetrics.searchTrailing))

            HStack(spacing: ptW(TikTokLayoutMetrics.topTabSpacing)) {
                topTab("Explore", isActive: false)
                topTab("Following", isActive: false)
                topTab("For You", isActive: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "magnifyingglass")
                .font(.system(size: ptW(TikTokLayoutMetrics.searchIconSize), weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                .padding(.trailing, ptW(TikTokLayoutMetrics.searchTrailing))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, ptH(TikTokLayoutMetrics.topBarInset))
    }

    private func topTab(_ title: String, isActive: Bool) -> some View {
        VStack(spacing: ptH(4)) {
            Text(title)
                .font(.system(size: ptW(TikTokLayoutMetrics.topTabFontSize), weight: isActive ? .bold : .semibold))
                .foregroundStyle(.white.opacity(isActive ? 1 : 0.75))

            if isActive {
                Capsule()
                    .fill(.white)
                    .frame(width: ptW(TikTokLayoutMetrics.topTabUnderlineWidth), height: ptH(TikTokLayoutMetrics.topTabUnderlineHeight))
            } else {
                Color.clear
                    .frame(width: ptW(TikTokLayoutMetrics.topTabUnderlineWidth), height: ptH(TikTokLayoutMetrics.topTabUnderlineHeight))
            }
        }
        .shadow(color: .black.opacity(isActive ? 0.45 : 0.3), radius: 2, x: 0, y: 1)
    }

    // MARK: - Bottom navigation

    private var bottomNavigationBar: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            HStack(spacing: 0) {
                navTab(icon: "house.fill", label: "Home", isActive: true)
                navTab(icon: "person.2.fill", label: "Friends", isActive: false, showsBadge: true)
                createTabButton
                navTab(icon: "tray.full.fill", label: "Inbox", isActive: false)
                navTab(icon: "person.fill", label: "Profile", isActive: false)
            }
            .frame(height: navBarHeight)
            .frame(maxWidth: .infinity)
            .background(Color.black)
        }
    }

    private var createTabButton: some View {
        let width = ptW(TikTokLayoutMetrics.createButtonWidth)
        let height = ptW(TikTokLayoutMetrics.createButtonHeight)
        let accent = ptW(TikTokLayoutMetrics.createAccentWidth)

        return ZStack {
            RoundedRectangle(cornerRadius: ptW(6), style: .continuous)
                .fill(.white)
                .frame(width: width, height: height)

            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.cyan)
                    .frame(width: accent, height: height)
                Spacer(minLength: 0)
                Rectangle()
                    .fill(Color(red: 1, green: 0.2, blue: 0.6))
                    .frame(width: accent, height: height)
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: ptW(6), style: .continuous))

            Image(systemName: "plus")
                .font(.system(size: ptW(TikTokLayoutMetrics.createPlusSize), weight: .bold))
                .foregroundStyle(.black)
        }
        .frame(maxWidth: .infinity)
    }

    private func navTab(
        icon: String,
        label: String,
        isActive: Bool,
        showsBadge: Bool = false
    ) -> some View {
        VStack(spacing: ptH(2)) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: ptW(TikTokLayoutMetrics.navIconSize), weight: isActive ? .bold : .regular))
                    .foregroundStyle(isActive ? .white : .white.opacity(0.72))

                if showsBadge {
                    Circle()
                        .fill(Color.red)
                        .frame(
                            width: ptW(TikTokLayoutMetrics.navBadgeSize),
                            height: ptW(TikTokLayoutMetrics.navBadgeSize)
                        )
                        .offset(x: ptW(4), y: ptH(-2))
                }
            }
            .frame(height: ptW(TikTokLayoutMetrics.navIconSize))

            Text(label)
                .font(.system(size: ptW(TikTokLayoutMetrics.navLabelSize), weight: isActive ? .bold : .medium))
                .foregroundStyle(isActive ? .white : .white.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Feedback pills

    private var feedbackPills: some View {
        HStack(spacing: ptW(TikTokLayoutMetrics.feedbackPillSpacing)) {
            feedbackPill(icon: "xmark", text: "Not interested")
            feedbackPill(icon: "checkmark", text: "Interested")
        }
        .padding(.horizontal, ptW(TikTokLayoutMetrics.leftInset))
        .padding(.bottom, ptH(TikTokLayoutMetrics.feedbackBottomOffset))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private func feedbackPill(icon: String, text: String) -> some View {
        HStack(spacing: ptW(6)) {
            Image(systemName: icon)
                .font(.system(size: ptW(11), weight: .semibold))
            Text(text)
                .font(.system(size: ptW(TikTokLayoutMetrics.feedbackPillFontSize), weight: .medium))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, ptW(TikTokLayoutMetrics.feedbackPillHPadding))
        .frame(height: ptH(TikTokLayoutMetrics.feedbackPillHeight))
        .background(.black.opacity(0.45), in: Capsule())
    }

    // MARK: - Bottom-left username + caption

    private var bottomLeftInfo: some View {
        VStack(alignment: .leading, spacing: ptH(TikTokLayoutMetrics.leftStackItemSpacing)) {
            Text("Flo")
                .font(.system(size: ptW(TikTokLayoutMetrics.usernameFontSize), weight: .bold))
                .foregroundStyle(.white)

            Text("I don't know how to decorate my bedroom in my summer house")
                .font(.system(size: ptW(TikTokLayoutMetrics.captionFontSize), weight: .regular))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .frame(maxWidth: w * TikTokLayoutMetrics.leftStackMaxWidthFraction, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.leading, ptW(TikTokLayoutMetrics.leftInset))
        .padding(.trailing, w * TikTokLayoutMetrics.rightColumnReserveWidthFraction)
        .padding(.bottom, ptH(TikTokLayoutMetrics.leftStackBottomOffset))
        .shadow(color: .black.opacity(0.55), radius: 2, x: 0, y: 1)
    }

    // MARK: - Right action column

    private var rightActionColumn: some View {
        VStack(spacing: ptH(TikTokLayoutMetrics.actionSpacing)) {
            profileAvatarWithPlus
            actionItem(icon: "heart.fill", label: "1.8M")
            actionItem(icon: "ellipsis.bubble.fill", label: "3,457")
            actionItem(icon: "bookmark.fill", label: "68.1K")
            actionItem(icon: "arrowshape.turn.up.right.fill", label: "29.6K")
            musicDisc
        }
        .padding(.trailing, ptW(TikTokLayoutMetrics.rightColumnTrailing))
        .padding(.bottom, ptH(TikTokLayoutMetrics.rightColumnBottomOffset))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }

    private var profileAvatarWithPlus: some View {
        let avatarSize = ptW(TikTokLayoutMetrics.profileAvatarSize)
        let badgeSize = ptW(TikTokLayoutMetrics.profilePlusBadgeSize)

        return ZStack(alignment: .bottom) {
            Circle()
                .fill(Color.white.opacity(0.22))
                .frame(width: avatarSize, height: avatarSize)
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(0.85), lineWidth: 1.5)
                }
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: ptW(22)))
                        .foregroundStyle(.white.opacity(0.9))
                }

            Circle()
                .fill(Color.red)
                .frame(width: badgeSize, height: badgeSize)
                .overlay {
                    Image(systemName: "plus")
                        .font(.system(size: ptW(10), weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(y: badgeSize * 0.35)
        }
        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
    }

    private var musicDisc: some View {
        let size = ptW(TikTokLayoutMetrics.musicDiscSize)

        return Circle()
            .fill(
                AngularGradient(
                    colors: [.gray.opacity(0.7), .black.opacity(0.85), .gray.opacity(0.5), .black.opacity(0.85)],
                    center: .center
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1)
            }
            .overlay {
                Circle()
                    .fill(Color.black.opacity(0.75))
                    .frame(width: size * 0.38, height: size * 0.38)
            }
            .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
    }

    private func actionItem(icon: String, label: String) -> some View {
        VStack(spacing: ptH(TikTokLayoutMetrics.actionLabelGap)) {
            Image(systemName: icon)
                .font(.system(size: ptW(TikTokLayoutMetrics.actionIconSize), weight: .regular))
            Text(label)
                .font(.system(size: ptW(TikTokLayoutMetrics.actionCountSize), weight: .semibold))
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Previews

private struct TikTokGuidePreviewBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.45, green: 0.55, blue: 0.65), Color(red: 0.25, green: 0.30, blue: 0.38)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview("TikTok — 720×1280 (recording canvas)") {
    TikTokGuideOverlayView(canvasSize: CGSize(width: 720, height: 1280))
        .background(TikTokGuidePreviewBackground())
}

#Preview("TikTok — 414×896 (iPhone 11)") {
    TikTokGuideOverlayView(canvasSize: CGSize(width: 414, height: 896))
        .background(TikTokGuidePreviewBackground())
}
