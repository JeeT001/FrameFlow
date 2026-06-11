//
//  EditorClipInfoSection.swift
//  FrameFlow
//

import SwiftUI

struct EditorClipInfoSection: View {
    let recording: RecordingMetadata
    let sourceDurationSeconds: Double
    let exportDurationSeconds: Double
    let masterTimelineDurationSeconds: Double
    let hasTrimApplied: Bool
    let hasRemovedRegions: Bool
    let formattedExportDuration: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.name)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)

                    Text(recording.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(recording.resolutionBadge)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 10
            ) {
                infoTile(icon: "clock", title: "Source", value: formatDuration(sourceDurationSeconds))
                infoTile(
                    icon: "scissors",
                    title: hasTrimApplied || hasRemovedRegions ? "Export" : "Length",
                    value: formattedExportDuration
                )
                infoTile(icon: "aspectratio", title: "Resolution", value: recording.resolution)
                infoTile(icon: "doc", title: "File size", value: recording.formattedFileSize)
                infoTile(icon: "film", title: "Format", value: recording.format)
                infoTile(icon: "square.grid.2x2", title: "Layout", value: layoutLabel)
            }

            if masterTimelineDurationSeconds > exportDurationSeconds + 0.05 {
                Label(
                    "Timeline \(TrimHelpers.formatTimelineTime(masterTimelineDurationSeconds)) incl. imported audio",
                    systemImage: "waveform"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var layoutLabel: String {
        recording.layout.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func infoTile(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)

            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatDuration(_ seconds: Double) -> String {
        TrimHelpers.formatTimelineTime(seconds)
    }
}
