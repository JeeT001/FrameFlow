//
//  RecordingBottomBar.swift
//  FrameFlow
//

import SwiftUI

struct RecordingBottomBar: View {
    let windowCount: Int
    let layoutPreset: LayoutPreset
    let format: RecordingFormat
    let autoFocusEnabled: Bool
    let audioMode: AudioModeOption
    let cameraEnabled: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                RecordingSessionChip(
                    icon: "macwindow.on.rectangle",
                    title: "\(windowCount) Window\(windowCount == 1 ? "" : "s")"
                )

                RecordingLayoutMiniPreview(activePreset: layoutPreset)

                RecordingSessionChip(
                    icon: format == .nineBySixteen ? "iphone" : "rectangle",
                    title: formatDisplayTitle
                )

                RecordingSessionChip(
                    icon: "viewfinder.circle",
                    title: "Auto Focus",
                    isOn: autoFocusEnabled
                )

                RecordingSessionChip(icon: audioMode.systemImage, title: audioMode.title) {
                    RecordingDecorativeWaveform()
                }

                RecordingSessionChip(
                    icon: "person.crop.circle",
                    title: "Camera (PiP)",
                    isOn: cameraEnabled
                ) {
                    if cameraEnabled {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(width: 20, height: 20)
                            .background(AppColors.surface, in: Circle())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .padding(.vertical, 12)
        .background(AppColors.background.opacity(0.92))
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var formatDisplayTitle: String {
        switch format {
        case .nineBySixteen:
            "9:16 Vertical"
        case .sixteenByNine:
            "16:9 Horizontal"
        }
    }
}

private struct RecordingDecorativeWaveform: View {
    private let barHeights: [CGFloat] = [4, 9, 12, 7, 5]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(barHeights.enumerated()), id: \.offset) { _, height in
                RoundedRectangle(cornerRadius: 1)
                    .fill(AppColors.successGreen.opacity(0.75))
                    .frame(width: 2, height: height)
            }
        }
        .frame(width: 24, height: 14, alignment: .center)
    }
}
