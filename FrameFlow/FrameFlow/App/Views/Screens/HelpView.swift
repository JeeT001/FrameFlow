//
//  HelpView.swift
//  FrameFlow
//

import AppKit
import SwiftUI

struct HelpView: View {
    private var faqItems: [HelpFAQItem] {
        faqItems(saveFolder: SettingsStore.shared.expandedSaveFolder)
    }

    private func faqItems(saveFolder: String) -> [HelpFAQItem] {
        [
        HelpFAQItem(
            title: "How do I grant screen recording permission?",
            answer: """
            Open Settings → Permissions, then tap Open System Settings next to Screen Recording. \
            Enable FrameFlow in System Settings → Privacy & Security → Screen Recording. \
            Return to FrameFlow and tap Check Status to refresh.
            """
        ),
        HelpFAQItem(
            title: "How do I enable camera and microphone access?",
            answer: """
            In Settings → Permissions, use Open System Settings for Camera and Microphone. \
            Grant access for FrameFlow, then tap Check Status. Camera is used for PiP overlays; \
            the microphone captures your voice when an audio mode includes the mic.
            """
        ),
        HelpFAQItem(
            title: "What is the difference between Free and Pro?",
            answer: """
            Free includes core recording with limits on windows and export options. Pro unlocks \
            higher limits (more windows, 4K on Apple Silicon), advanced layouts, and priority \
            features. Subscription billing will be available in a future update; pricing is shown \
            on the Subscription screen.
            """
        ),
        HelpFAQItem(
            title: "Does FrameFlow capture system audio?",
            answer: """
            Yes — on macOS 14 and later, FrameFlow can capture system audio without a virtual \
            audio cable. Choose System Audio or Combined in Settings → Audio (or during setup \
            before recording in a later release).
            """
        ),
        HelpFAQItem(
            title: "What export formats and resolutions are supported?",
            answer: """
            Exports support 16:9 (landscape) and 9:16 (vertical) aspect ratios. Default \
            resolution is set in Settings → Recording & Export (720p, 1080p, and 4K on Apple \
            Silicon). Final export options are configured on the Export screen after recording.
            """
        ),
        HelpFAQItem(
            title: "How do captions work?",
            answer: """
            Captions are generated on-device using WhisperKit in a later phase — no audio is sent \
            to the cloud for transcription. You can edit segments in the Caption Editor and burn \
            them into the exported video.
            """
        ),
        HelpFAQItem(
            title: "Where are my recordings saved?",
            answer: """
            Recordings are saved to your default folder in Settings → Recording & Export. \
            Current folder: \(saveFolder). Use Choose… to pick another directory. \
            Recording metadata is stored locally by the app.
            """
        ),
        HelpFAQItem(
            title: "How do I contact support?",
            answer: """
            Tap Email Support below to open your mail app, or write to support@frameflow.app. \
            Include your macOS version and a short description of the issue for faster help.
            """
        ),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Help & Support")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Answers to common questions about permissions, recording, and exports.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(faqItems) { item in
                    DisclosureGroup(item.title) {
                        Text(item.answer)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Button("Email Support") {
                        openEmailSupport()
                    }
                    .buttonStyle(.borderedProminent)

                    LabeledContent("App version") {
                        Text(appVersionString)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: 640, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Help")
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func openEmailSupport() {
        // TODO: Replace with production support address when confirmed.
        guard let url = URL(string: "mailto:support@frameflow.app?subject=FrameFlow%20Support") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

private struct HelpFAQItem: Identifiable {
    let id = UUID()
    let title: String
    let answer: String
}

#Preview {
    HelpView()
        .frame(width: 640, height: 720)
}
