//
//  PlatformPreviewOverlay.swift
//  FrameFlow
//

import Foundation

/// Mock platform chrome for Layout Picker live preview only — never recorded or exported.
enum PlatformPreviewOverlay: String, CaseIterable, Identifiable {
    case none
    case youtubeShorts
    case instagramReels
    case tiktok

    var id: String { rawValue }

    var pickerTitle: String {
        switch self {
        case .none: "None"
        case .youtubeShorts: "YouTube Shorts"
        case .instagramReels: "Reels"
        case .tiktok: "TikTok"
        }
    }
}
