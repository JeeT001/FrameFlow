//
//  EditorExportSheet.swift
//  FrameFlow
//

import SwiftUI

struct EditorExportSheet: View {
    @Environment(\.dismiss) private var dismiss

    let recordingName: String?
    let exportSummary: [String]
    let exportVM: ExportViewModel
    let isPro: Bool
    let onExport: () -> Void
    let onShowProGate: (String, String) -> Void

    private var saveFolderNeedsReauthorization: Bool {
        SettingsStore.shared.defaultSaveFolderBookmarkData == nil
    }

    var body: some View {
        ScrollView {
            exportSheetContent
        }
        .frame(minWidth: 420, minHeight: 480)
    }

    private var exportSheetContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Export recording")
                .font(.title2.weight(.semibold))

            if let recordingName {
                Text(recordingName)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }

            whatsIncludedSection

            exportResolutionSection

            if exportVM.hasCaptionsAvailable {
                Toggle("Include captions in export", isOn: Binding(
                    get: { exportVM.applyCaptions },
                    set: { exportVM.applyCaptions = $0 }
                ))

                if isPro {
                    Toggle("Also save SRT file", isOn: Binding(
                        get: { exportVM.alsoSaveSRT },
                        set: { exportVM.alsoSaveSRT = $0 }
                    ))
                    Text("SRT saved next to exported MP4 in your save folder.")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            if !isPro {
                Label("Free exports include a FrameFlow watermark", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if saveFolderNeedsReauthorization {
                Text("Choose… your save folder again in Settings → Recording & Export before exporting to Desktop or other protected locations.")
                    .font(.caption)
                    .foregroundStyle(AppColors.proGold)
            }

            if let exportError = exportVM.exportError {
                Text(exportError)
                    .font(.subheadline)
                    .foregroundStyle(AppColors.recRed)
            }

            if exportVM.isExporting {
                ProgressView(value: exportVM.progress)
                Text(exportVM.statusMessage)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    onExport()
                } label: {
                    if exportVM.isExporting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Export")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(exportVM.isExporting || exportVM.recording == nil)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
    }

    private var whatsIncludedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's included")
                .font(.subheadline.weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                ForEach(exportSummary, id: \.self) { line in
                    Label(line, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var exportResolutionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resolution")
                .font(.subheadline.weight(.semibold))

            ForEach(ExportResolution.allCases) { resolution in
                exportResolutionRow(resolution)
            }
        }
    }

    private func exportResolutionRow(_ resolution: ExportResolution) -> some View {
        let isLocked = !exportVM.canSelectResolution(resolution, isPro: isPro)
        let isSelected = exportVM.selectedResolution == resolution

        return Button {
            if isLocked {
                onShowProGate(
                    resolution == .p4K ? "4K Export" : "1080p Export",
                    exportVM.lockReason(for: resolution, isPro: isPro)
                        ?? "HD export requires FrameFlow Pro."
                )
            } else {
                exportVM.selectedResolution = resolution
            }
        } label: {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.textSecondary)

                Text(resolution.displayName)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(exportVM.lockReason(for: resolution, isPro: isPro) ?? "")
    }
}
