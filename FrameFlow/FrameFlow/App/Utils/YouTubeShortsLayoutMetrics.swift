//
//  YouTubeShortsLayoutMetrics.swift
//  FrameFlow
//

import CoreGraphics

/// iPhone 11 logical dimensions for YouTube Shorts mock chrome (414×896 pt).
enum YouTubeShortsLayoutMetrics {
    static let referenceWidth: CGFloat = 414
    static let referenceHeight: CGFloat = 896

    // Bottom chrome
    static let navBarHeight: CGFloat = 56
    static let progressBarHeight: CGFloat = 2
    static let leftInset: CGFloat = 12
    static let leftStackMaxWidthFraction: CGFloat = 0.72
    static let rightColumnTrailing: CGFloat = 10
    static let rightColumnReserveWidthFraction: CGFloat = 0.22

    // Typography & icons (iPhone pt)
    static let actionIconSize: CGFloat = 26
    static let actionLabelSize: CGFloat = 11
    static let actionSpacing: CGFloat = 20
    static let actionLabelGap: CGFloat = 4
    static let musicThumbSize: CGFloat = 36
    static let musicThumbCornerRadius: CGFloat = 4

    static let navIconSize: CGFloat = 22
    static let navCreateIconSize: CGFloat = 28
    static let navLabelSize: CGFloat = 10
    static let navBadgeSize: CGFloat = 7

    static let useThisSoundFontSize: CGFloat = 13
    static let channelFontSize: CGFloat = 13
    static let avatarSize: CGFloat = 28
    static let descriptionFontSize: CGFloat = 14
    static let songFontSize: CGFloat = 12

    static let leftStackItemSpacing: CGFloat = 8
    static let progressPlayheadSize: CGFloat = 6
    static let progressPlayheadXFraction: CGFloat = 0.05
    static let progressFilledWidthFraction: CGFloat = 0.05

    // Vertical offsets from canvas bottom (iPhone pt)
    static let rightColumnBottomOffset: CGFloat = 68
    static let leftStackBottomOffset: CGFloat = 62

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
