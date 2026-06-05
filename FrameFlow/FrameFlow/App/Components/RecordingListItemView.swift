//
//  RecordingListItemView.swift
//  FrameFlow
//

import SwiftUI

struct RecordingListItemView: View {
    let recording: RecordingMetadata
    var onTap: (() -> Void)?
    var onExport: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var thumbnail: NSImage?
    @State private var loadFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            previewSection

            VStack(alignment: .leading, spacing: 4) {
                Text(recording.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(recording.formattedDate)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)

                HStack(spacing: 8) {
                    Text(recording.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)

                    Text(recording.resolutionBadge)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.primary.opacity(0.15), in: Capsule())
                }
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppColors.border)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture {
            onTap?()
        }
        .contextMenu {
            if let onExport {
                Button("Export…", action: onExport)
            }
            if let onDelete {
                Button("Delete", role: .destructive, action: onDelete)
            }
        }
        .task(id: recording.filePath) {
            loadFailed = false
            thumbnail = await RecordingThumbnailService.thumbnail(for: recording)
            loadFailed = thumbnail == nil
        }
    }

    private var previewSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppColors.surface)

            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if loadFailed {
                Image(systemName: "play.rectangle")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                ProgressView()
                    .controlSize(.small)
            }

            if thumbnail != nil {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.35))
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .frame(maxHeight: 140)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#if DEBUG
#Preview("16:9") {
    RecordingListItemView(
        recording: .mock(name: "Landscape Recording", format: "16:9"),
        onDelete: {}
    )
    .frame(width: 240)
    .padding()
}

#Preview("9:16") {
    RecordingListItemView(
        recording: .mock(name: "Portrait Recording", format: "9:16"),
        onDelete: {}
    )
    .frame(width: 240)
    .padding()
}
#endif
