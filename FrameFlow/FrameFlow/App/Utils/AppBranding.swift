//
//  AppBranding.swift
//  FrameFlow
//

import Foundation

/// User-facing product name. Internal bundle IDs, URL schemes, and storage paths stay on FrameFlow.
enum AppBranding {
    static let name = "Drazlo"
    static let proName = "Drazlo Pro"
    static let watermarkText = "Made with Drazlo"
    static let creatorYouTubeURL = "https://www.youtube.com/@simranjit2000/featured"
    /// Shown in Finder Get Info and system About metadata (`NSHumanReadableCopyright`).
    static let copyrightNotice = "© 2026 Simranjit Babbar"
    /// Sparkle appcast RSS feed — keep in sync with Info.plist `SUFeedURL`.
    static let appcastFeedURL = "https://drazlo.vercel.app/appcast.xml"
}
