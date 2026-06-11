//
//  CaptionStyleConfig.swift
//  FrameFlow
//

import AppKit
import Foundation
import SwiftUI

enum CaptionStylePreset: String, Codable, CaseIterable, Sendable {
    case classic
    case tiktokBold
    case highlightedWord
    case minimal
    case custom
}

enum CaptionVerticalPosition: String, Codable, Sendable {
    case top
    case middle
    case bottom
}

struct CaptionStyleConfig: Codable, Equatable, Sendable {
    var preset: CaptionStylePreset
    var fontName: String
    var fontSize: CGFloat
    var textColorHex: String
    var backgroundColorHex: String?
    var showsBackground: Bool
    var verticalPosition: CaptionVerticalPosition
    /// Fine-tune offset from `verticalPosition` anchor, normalized to frame height (−0.3…+0.3; + moves up).
    var customVerticalOffsetNormalized: Double? = nil

    static let verticalOffsetRange: ClosedRange<Double> = -0.3...0.3

    var clampedVerticalOffset: Double {
        guard let offset = customVerticalOffsetNormalized else { return 0 }
        return min(max(offset, Self.verticalOffsetRange.lowerBound), Self.verticalOffsetRange.upperBound)
    }

    /// Core Animation Y origin for geometry-flipped parent layers (top-left origin, Y increases downward).
    /// Used with `CALayer.isGeometryFlipped = true` (matches SwiftUI preview).
    func captionOriginY(renderHeight: CGFloat, boxHeight: CGFloat) -> CGFloat {
        let margin = renderHeight * 0.08
        let baseY: CGFloat
        switch verticalPosition {
        case .top:
            baseY = margin
        case .middle:
            baseY = (renderHeight - boxHeight) / 2
        case .bottom:
            baseY = renderHeight - margin - boxHeight
        }
        // +offset moves up on screen → smaller Y in flipped space
        let offset = CGFloat(clampedVerticalOffset) * renderHeight
        let y = baseY - offset
        return min(max(y, margin), renderHeight - margin - boxHeight)
    }

    #if DEBUG
    /// Sanity check: bottom anchor sits lower on screen (larger Y) than top for the same box height.
    static func debugAssertCaptionYOrdering(renderHeight: CGFloat = 1080, boxHeight: CGFloat = 80) {
        var topStyle = CaptionStyleConfig.classic
        topStyle.verticalPosition = .top
        var bottomStyle = CaptionStyleConfig.classic
        bottomStyle.verticalPosition = .bottom
        let topY = topStyle.captionOriginY(renderHeight: renderHeight, boxHeight: boxHeight)
        let bottomY = bottomStyle.captionOriginY(renderHeight: renderHeight, boxHeight: boxHeight)
        assert(bottomY > topY, "Caption Y ordering inverted: top=\(topY) bottom=\(bottomY)")
    }
    #endif

    /// SwiftUI offset for preview overlay (+Y moves down on screen).
    func swiftUIVerticalOffset(containerHeight: CGFloat) -> CGFloat {
        -CGFloat(clampedVerticalOffset) * containerHeight
    }

    static func from(settingsValue: String) -> CaptionStyleConfig {
        switch settingsValue.lowercased() {
        case "bold":
            return .tiktokBold
        case "minimal":
            return .minimal
        case "highlighted", "highlightedword":
            return .highlightedWord
        case "custom":
            return .custom
        default:
            return .classic
        }
    }

    static func fromSettings() -> CaptionStyleConfig {
        from(settingsValue: SettingsStore.shared.captionStyle)
    }

    static func config(for preset: CaptionStylePreset, position: CaptionVerticalPosition) -> CaptionStyleConfig {
        var base: CaptionStyleConfig
        switch preset {
        case .classic:
            base = .classic
        case .tiktokBold:
            base = .tiktokBold
        case .highlightedWord:
            base = .highlightedWord
        case .minimal:
            base = .minimal
        case .custom:
            base = .custom
        }
        base.verticalPosition = position
        return base
    }

    var displayName: String {
        switch preset {
        case .classic: "Classic"
        case .tiktokBold: "TikTok Bold"
        case .highlightedWord: "Highlighted"
        case .minimal: "Minimal"
        case .custom: "Custom"
        }
    }

    var swiftUITextColor: Color {
        Color(nsColor: nsTextColor)
    }

    var swiftUIBackgroundColor: Color? {
        guard showsBackground, let hex = backgroundColorHex else { return nil }
        return Color(nsColor: NSColor(hex: hex) ?? .black)
    }

    static let classic = CaptionStyleConfig(
        preset: .classic,
        fontName: "Helvetica-Bold",
        fontSize: 42,
        textColorHex: "#FFFFFF",
        backgroundColorHex: "#000000",
        showsBackground: true,
        verticalPosition: .bottom
    )

    static let tiktokBold = CaptionStyleConfig(
        preset: .tiktokBold,
        fontName: "Helvetica-Bold",
        fontSize: 56,
        textColorHex: "#FFE135",
        backgroundColorHex: nil,
        showsBackground: false,
        verticalPosition: .middle
    )

    static let minimal = CaptionStyleConfig(
        preset: .minimal,
        fontName: "Helvetica",
        fontSize: 32,
        textColorHex: "#FFFFFF",
        backgroundColorHex: nil,
        showsBackground: false,
        verticalPosition: .bottom
    )

    /// Day 24 stub — full per-word highlight ships with Day 25 editor.
    static let highlightedWord = CaptionStyleConfig(
        preset: .highlightedWord,
        fontName: "Helvetica-Bold",
        fontSize: 44,
        textColorHex: "#FFFFFF",
        backgroundColorHex: "#000000CC",
        showsBackground: true,
        verticalPosition: .bottom
    )

    /// Day 24 stub — user-defined styling ships with Day 25 editor.
    static let custom = CaptionStyleConfig(
        preset: .custom,
        fontName: "Helvetica-Bold",
        fontSize: 42,
        textColorHex: "#FFFFFF",
        backgroundColorHex: "#000000",
        showsBackground: true,
        verticalPosition: .bottom
    )

    var nsTextColor: NSColor {
        NSColor(hex: textColorHex) ?? .white
    }

    var nsBackgroundColor: NSColor? {
        guard showsBackground, let hex = backgroundColorHex else { return nil }
        return NSColor(hex: hex)
    }
}

private extension NSColor {
    convenience init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        if cleaned.count == 8 {
            // RGBA
            guard let value = UInt64(cleaned, radix: 16) else { return nil }
            let r = CGFloat((value >> 24) & 0xFF) / 255
            let g = CGFloat((value >> 16) & 0xFF) / 255
            let b = CGFloat((value >> 8) & 0xFF) / 255
            let a = CGFloat(value & 0xFF) / 255
            self.init(srgbRed: r, green: g, blue: b, alpha: a)
            return
        }
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return nil }
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
