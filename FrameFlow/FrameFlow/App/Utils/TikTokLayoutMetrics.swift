//
//  TikTokLayoutMetrics.swift
//  FrameFlow
//

import CoreGraphics

/// iPhone 11 logical dimensions for TikTok For You mock chrome (414×896 pt).
enum TikTokLayoutMetrics {
    static let referenceWidth: CGFloat = 414
    static let referenceHeight: CGFloat = 896

    // Top bar
    static let topBarInset: CGFloat = 12
    static let topTabFontSize: CGFloat = 16
    static let topTabSpacing: CGFloat = 16
    static let topTabUnderlineWidth: CGFloat = 24
    static let topTabUnderlineHeight: CGFloat = 2
    static let searchIconSize: CGFloat = 22
    static let searchTrailing: CGFloat = 12

    // Bottom navigation
    static let navBarHeight: CGFloat = 56
    static let navIconSize: CGFloat = 22
    static let navLabelSize: CGFloat = 10
    static let navBadgeSize: CGFloat = 7
    static let createButtonWidth: CGFloat = 48
    static let createButtonHeight: CGFloat = 30
    static let createAccentWidth: CGFloat = 3
    static let createPlusSize: CGFloat = 18

    // Right action column
    static let rightColumnTrailing: CGFloat = 8
    static let rightColumnBottomOffset: CGFloat = 118
    static let rightColumnReserveWidthFraction: CGFloat = 0.20
    static let profileAvatarSize: CGFloat = 48
    static let profilePlusBadgeSize: CGFloat = 16
    static let actionIconSize: CGFloat = 35
    static let actionCountSize: CGFloat = 12
    static let actionSpacing: CGFloat = 16
    static let actionLabelGap: CGFloat = 4
    static let musicDiscSize: CGFloat = 44

    // Bottom-left info
    static let leftInset: CGFloat = 12
    static let leftStackMaxWidthFraction: CGFloat = 0.72
    static let leftStackBottomOffset: CGFloat = 100
    static let leftStackItemSpacing: CGFloat = 6
    static let usernameFontSize: CGFloat = 15
    static let captionFontSize: CGFloat = 14

    // Feedback pills
    static let feedbackPillHeight: CGFloat = 32
    static let feedbackPillSpacing: CGFloat = 8
    static let feedbackPillHPadding: CGFloat = 12
    static let feedbackPillFontSize: CGFloat = 12
    static let feedbackBottomOffset: CGFloat = 56

    static func ptWidth(_ iphonePt: CGFloat, canvasWidth: CGFloat) -> CGFloat {
        iphonePt * canvasWidth / referenceWidth
    }

    static func ptHeight(_ iphonePt: CGFloat, canvasHeight: CGFloat) -> CGFloat {
        iphonePt * canvasHeight / referenceHeight
    }

    static func navBarHeight(for canvasHeight: CGFloat) -> CGFloat {
        ptHeight(navBarHeight, canvasHeight: canvasHeight)
    }
}
