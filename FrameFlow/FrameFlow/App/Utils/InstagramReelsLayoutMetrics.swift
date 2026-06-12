//
//  InstagramReelsLayoutMetrics.swift
//  FrameFlow
//

import CoreGraphics

/// iPhone 11 logical dimensions for Instagram Reels mock chrome (414×896 pt).
enum InstagramReelsLayoutMetrics {
    static let referenceWidth: CGFloat = 414
    static let referenceHeight: CGFloat = 896

    // Bottom navigation (icon-only, no labels)
    static let navBarHeight: CGFloat = 49
    static let navIconSize: CGFloat = 24
    static let navCreateIconSize: CGFloat = 26

    // Right action column
    static let rightColumnTrailing: CGFloat = 12
    static let rightColumnBottomOffset: CGFloat = 54
    static let rightColumnReserveWidthFraction: CGFloat = 0.18
    static let actionIconSize: CGFloat = 28
    static let actionCountSize: CGFloat = 12
    static let actionSpacing: CGFloat = 18
    static let actionLabelGap: CGFloat = 4
    static let moreIconSize: CGFloat = 22
    static let audioThumbSize: CGFloat = 32
    static let audioThumbCornerRadius: CGFloat = 6

    // Bottom-left info
    static let leftInset: CGFloat = 12
    static let leftStackMaxWidthFraction: CGFloat = 0.78
    static let leftStackBottomOffset: CGFloat = 58
    static let leftStackItemSpacing: CGFloat = 8

    static let avatarSize: CGFloat = 32
    static let avatarRingWidth: CGFloat = 2
    static let avatarRingOuterPadding: CGFloat = 2
    static let usernameFontSize: CGFloat = 14
    static let verifiedBadgeSize: CGFloat = 12
    static let followFontSize: CGFloat = 13
    static let followButtonHPadding: CGFloat = 10
    static let followButtonVPadding: CGFloat = 4
    static let captionFontSize: CGFloat = 14

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
