//
//  HelpFAQItem.swift
//  FrameFlow
//

import Foundation

enum HelpFAQCategory: String, CaseIterable, Identifiable {
    case gettingStarted = "Getting started"
    case plansAndFeatures = "Plans & features"
    case recordingAndExport = "Recording & export"
    case captions = "Captions"
    case shortcuts = "Shortcuts"
    case support = "Support"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .gettingStarted: "play.circle"
        case .plansAndFeatures: "star.circle"
        case .recordingAndExport: "film"
        case .captions: "captions.bubble"
        case .shortcuts: "command"
        case .support: "envelope"
        }
    }
}

enum HelpFAQAnswerBlock: Hashable {
    case paragraph(String)
    case bullets([String])
}

struct HelpFAQItem: Identifiable, Hashable {
    let id = UUID()
    let category: HelpFAQCategory
    let title: String
    let blocks: [HelpFAQAnswerBlock]

    var searchableText: String {
        let blockText = blocks.map { block -> String in
            switch block {
            case .paragraph(let text):
                return text
            case .bullets(let items):
                return items.joined(separator: " ")
            }
        }
        .joined(separator: " ")
        return "\(title) \(blockText)"
    }

    static func allItems(saveFolder: String, supportEmail: String) -> [HelpFAQItem] {
        [
            HelpFAQItem(
                category: .gettingStarted,
                title: "How do I grant screen recording permission?",
                blocks: [
                    .paragraph(
                        """
                        Open Settings → Permissions, then tap Open System Settings next to Screen Recording. \
                        Enable \(AppBranding.name) in System Settings → Privacy & Security → Screen Recording. \
                        Return to \(AppBranding.name) and tap Check Status to refresh.
                        """
                    )
                ]
            ),
            HelpFAQItem(
                category: .gettingStarted,
                title: "How do I enable camera and microphone access?",
                blocks: [
                    .paragraph(
                        """
                        In Settings → Permissions, use Open System Settings for Camera and Microphone. \
                        Grant access for \(AppBranding.name), then tap Check Status. Camera is used for PiP overlays; \
                        the microphone captures your voice when an audio mode includes the mic.
                        """
                    )
                ]
            ),
            HelpFAQItem(
                category: .plansAndFeatures,
                title: "What is the difference between Free and Pro?",
                blocks: [
                    .paragraph(
                        """
                        Free includes core recording with limits — up to 2 windows and standard export options. \
                        Pro unlocks up to 4 windows on supported Macs, 4K export on Apple Silicon, 9:16 vertical \
                        layouts, camera PiP, on-device captions, and more. Manage your plan on the Subscription \
                        screen (Settings or Account).
                        """
                    )
                ]
            ),
            HelpFAQItem(
                category: .plansAndFeatures,
                title: "Does \(AppBranding.name) capture system audio?",
                blocks: [
                    .paragraph(
                        """
                        Yes — on macOS 14 and later, \(AppBranding.name) can capture system audio without a virtual \
                        audio cable. Choose System Audio or Combined in Settings → Audio, or pick your audio \
                        mode in the Layout Picker audio sheet before recording.
                        """
                    )
                ]
            ),
            HelpFAQItem(
                category: .recordingAndExport,
                title: "What export formats and resolutions are supported?",
                blocks: [
                    .paragraph(
                        """
                        Exports support 16:9 (landscape) and 9:16 (vertical) aspect ratios. Default \
                        resolution is set in Settings → Recording & Export (720p, 1080p, and 4K on Apple \
                        Silicon). After recording, the Post-Record Editor opens automatically — tap Export \
                        Video in the toolbar to choose resolution and save your MP4. You can also re-export \
                        from Home via a recording's context menu.
                        """
                    )
                ]
            ),
            HelpFAQItem(
                category: .recordingAndExport,
                title: "Where are my recordings saved?",
                blocks: [
                    .paragraph(
                        """
                        Recordings are saved to your default folder in Settings → Recording & Export. \
                        Current folder: \(saveFolder). Use Choose… to pick another directory. \
                        Recording metadata is stored locally by the app.
                        """
                    )
                ]
            ),
            HelpFAQItem(
                category: .captions,
                title: "How do captions work?",
                blocks: [
                    .paragraph(
                        """
                        Captions are generated on-device using WhisperKit — no audio is sent to the cloud. \
                        Pro users can generate and edit captions in the Post-Record Editor sidebar, then \
                        export with captions burned in from Export Video in the toolbar.
                        """
                    )
                ]
            ),
            HelpFAQItem(
                category: .shortcuts,
                title: "What keyboard shortcuts work while recording?",
                blocks: [
                    .paragraph(
                        """
                        Global shortcuts work during an active recording session. \(AppBranding.name) must be allowed in \
                        System Settings → Privacy & Security → Accessibility for shortcuts when another app is focused:
                        """
                    ),
                    .bullets([
                        "Cmd+R — Stop recording",
                        "Cmd+P — Pause / Resume",
                        "Cmd+= — Zoom in (+0.25×)",
                        "Cmd+- — Zoom out (−0.25×)",
                        "Cmd+0 — Reset zoom to 1.0×",
                        "Cmd+F — Toggle auto-focus on active window",
                        "Cmd+H — Toggle cursor highlight",
                        "Cmd+K — Toggle camera PiP (Pro)",
                        "Cmd+Escape — Discard recording without saving"
                    ])
                ]
            ),
            HelpFAQItem(
                category: .support,
                title: "How do I contact support?",
                blocks: [
                    .paragraph(
                        """
                        Tap Email Support below to open your mail app, or write to \(supportEmail). \
                        Include your macOS version and a short description of the issue for faster help.
                        """
                    )
                ]
            ),
        ]
    }
}
