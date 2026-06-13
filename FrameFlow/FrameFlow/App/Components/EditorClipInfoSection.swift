//
//  EditorClipInfoSection.swift
//  FrameFlow
//

import SwiftUI

struct EditorClipInfoSection: View {
    let recording: RecordingMetadata
    let sourceDurationSeconds: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)

                    Text(recording.formattedDate)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer(minLength: 8)

                Text(recording.resolutionBadge)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppColors.textSecondary)
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 10
            ) {
                infoTile(icon: "clock", title: "Duration", value: formatDuration(sourceDurationSeconds))
                infoTile(icon: "aspectratio", title: "Resolution", value: recording.resolution)
                infoTile(icon: "film", title: "Format", value: recording.format)
                infoTile(icon: "doc", title: "File size", value: recording.formattedFileSize)
                infoTile(icon: "waveform", title: "Audio", value: audioModeLabel)
                infoTile(icon: "square.grid.2x2", title: "Layout", value: layoutLabel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var layoutLabel: String {
        recording.layout.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var audioModeLabel: String {
        recording.audioMode.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func infoTile(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .labelStyle(.titleAndIcon)

            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatDuration(_ seconds: Double) -> String {
        TrimHelpers.formatTimelineTime(seconds)
    }
}
