//
//  PlatformSafeZoneOverlayView.swift
//  FrameFlow
//

import SwiftUI

/// Routes platform preview guides onto the Layout Picker canvas.
struct PlatformSafeZoneOverlayView: View {
    let platform: PlatformPreviewOverlay
    let canvasSize: CGSize

    var body: some View {
        Group {
            switch platform {
            case .none:
                EmptyView()
            case .youtubeShorts:
                YouTubeShortsGuideOverlayView(canvasSize: canvasSize)
            case .instagramReels:
                InstagramReelsGuideOverlayView(canvasSize: canvasSize)
            case .tiktok:
                TikTokGuideOverlayView(canvasSize: canvasSize)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .allowsHitTesting(false)
    }
}

#Preview("YouTube Shorts") {
    PlatformSafeZoneOverlayView(
        platform: .youtubeShorts,
        canvasSize: CGSize(width: 360, height: 640)
    )
    .background(Color.gray.opacity(0.3))
}
