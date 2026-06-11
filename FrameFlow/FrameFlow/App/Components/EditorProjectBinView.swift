//
//  EditorProjectBinView.swift
//  FrameFlow
//

import SwiftUI

struct EditorProjectBinView: View {
    let recordingName: String
    let hasImageOverlay: Bool
    let imageFileName: String?
    let hasImportedAudio: Bool
    let audioFileName: String?
    let onImportImage: () -> Void
    let onImportAudio: () -> Void
    let onRemoveImage: () -> Void
    let onRemoveAudio: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)

            binRow(
                icon: "film",
                title: recordingName,
                subtitle: "Main recording",
                isPrimary: true
            )

            if hasImageOverlay, let imageFileName {
                binRow(
                    icon: "photo",
                    title: imageFileName,
                    subtitle: "Image overlay",
                    isPrimary: false,
                    onRemove: onRemoveImage
                )
            }

            if hasImportedAudio, let audioFileName {
                binRow(
                    icon: "waveform",
                    title: audioFileName,
                    subtitle: "Imported audio",
                    isPrimary: false,
                    onRemove: onRemoveAudio
                )
            }

            Spacer(minLength: 0)

            Menu {
                Button {
                    onImportImage()
                } label: {
                    Label("Import image…", systemImage: "photo")
                }
                .disabled(hasImageOverlay)

                Button {
                    onImportAudio()
                } label: {
                    Label("Import audio…", systemImage: "waveform")
                }
                .disabled(hasImportedAudio)
            } label: {
                Label("Import", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
            }
            .menuStyle(.borderedButton)
        }
        .padding(10)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func binRow(
        icon: String,
        title: String,
        subtitle: String,
        isPrimary: Bool,
        onRemove: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(isPrimary ? AppColors.primary : AppColors.textSecondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 0)

            if let onRemove {
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isPrimary ? AppColors.primary.opacity(0.1) : Color.clear)
        )
    }
}
