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
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            previewSection

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)

                    Text(recording.formattedDate)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer(minLength: 0)

                cardMenu
            }

            metadataPills
        }
        .padding(14)
        .background(AppColors.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColors.border.opacity(isHovered ? 0.9 : 0.6), lineWidth: 1)
        }
        .shadow(color: .black.opacity(isHovered ? 0.1 : 0.04), radius: isHovered ? 10 : 4, y: isHovered ? 4 : 2)
        .scaleEffect(isHovered ? 1.015 : 1)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture {
            onTap?()
        }
        .contextMenu {
            cardContextActions
        }
        .onHover { isHovered = $0 }
        .task(id: recording.filePath) {
            loadFailed = false
            thumbnail = await RecordingThumbnailService.thumbnail(for: recording)
            loadFailed = thumbnail == nil
        }
    }

    @ViewBuilder
    private var cardContextActions: some View {
        if let onExport {
            Button("Export…", action: onExport)
        }
        if let onDelete {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    private var cardMenu: some View {
        Menu {
            cardContextActions
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.medium))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private var metadataPills: some View {
        HStack(spacing: 6) {
            metadataPill(recording.resolutionBadge)
            metadataPill(recording.format)
        }
    }

    private func metadataPill(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(AppColors.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColors.primary.opacity(0.12), in: Capsule())
    }

    private var previewSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppColors.surface)

            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if loadFailed {
                Image(systemName: "play.rectangle")
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                ProgressView()
                    .controlSize(.small)
            }

            if thumbnail != nil {
                Color.black.opacity(isHovered ? 0.18 : 0.28)

                Image(systemName: "play.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(.black.opacity(0.45), in: Circle())
                    .scaleEffect(isHovered ? 1.06 : 1)
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(recording.formattedDuration)
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.65), in: Capsule())
                }
            }
            .padding(8)
        }
        .aspectRatio(recording.previewAspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: recording.format == "9:16" ? 200 : 150)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#if DEBUG
#Preview("16:9") {
    RecordingListItemView(
        recording: .mock(name: "Code Walkthrough", format: "16:9"),
        onDelete: {}
    )
    .frame(width: 260)
    .padding()
}

#Preview("9:16") {
    RecordingListItemView(
        recording: .mock(name: "Portrait Recording", format: "9:16"),
        onDelete: {}
    )
    .frame(width: 260)
    .padding()
}
#endif
