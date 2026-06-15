//
//  ExportView.swift
//  FrameFlow
//

import AVKit
import SwiftUI

struct ExportView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = ExportViewModel()
    @State private var showProGate = false
    @State private var proGateFeature = ""
    @State private var proGateDescription = ""

    var body: some View {
        Group {
            if viewModel.recording == nil {
                missingRecordingView
            } else {
                exportContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Export")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Discard") {
                    discardAndLeave()
                }
            }
        }
        .onAppear {
            viewModel.load(
                exportRecordingID: appState.exportRecordingID,
                pendingRecording: appState.pendingRecording,
                isPro: appState.isPro
            )
        }
        .onDisappear {
            viewModel.teardown()
        }
        .proUpgradeSheet(
            isPresented: $showProGate,
            feature: proGateFeature,
            description: proGateDescription
        )
        .alert("Export complete", isPresented: $viewModel.showSuccessAlert) {
            Button("Reveal in Finder") {
                viewModel.revealInFinder()
            }
            Button("Dashboard") {
                appState.exportRecordingID = nil
                appState.pendingRecording = nil
                router.navigate(to: .dashboard)
            }
            Button("OK", role: .cancel) {
                appState.exportRecordingID = nil
                appState.pendingRecording = nil
            }
        } message: {
            if let url = viewModel.exportedURL {
                Text(url.path)
            }
        }
    }

    private var exportContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let recording = viewModel.recording {
                    Text(recording.name)
                        .font(.title2.weight(.semibold))

                    HStack(spacing: 16) {
                        Text(recording.formattedDuration)
                        Text(recording.formattedFileSize)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .font(.subheadline)
                }

                let previewAspect = viewModel.recording?.previewAspectRatio ?? (16.0 / 9.0)

                VideoPlayer(player: viewModel.player)
                    .aspectRatio(previewAspect, contentMode: .fit)
                    .frame(maxWidth: 480, maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 10))

                resolutionSection

                if viewModel.hasCaptionsAvailable {
                    Toggle("Include captions in export", isOn: $viewModel.applyCaptions)
                }

                if viewModel.showsCaptionsBadge {
                    Label("Captions included", systemImage: "captions.bubble.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.successGreen)
                }

                if !appState.isPro {
                    Label("Free exports include a \(AppBranding.name) watermark", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                if SettingsStore.shared.defaultSaveFolderBookmarkData == nil {
                    Text("Choose… your save folder again in Settings → Recording & Export before exporting to Desktop or other protected locations.")
                        .font(.caption)
                        .foregroundStyle(AppColors.proGold)
                }

                if let exportError = viewModel.exportError {
                    Text(exportError)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.recRed)
                }

                if viewModel.isExporting {
                    ProgressView(value: viewModel.progress)
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Button {
                    Task { await viewModel.export(isPro: appState.isPro, appState: appState) }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isExporting || viewModel.recording == nil)
            }
            .padding(24)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var resolutionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resolution")
                .font(.subheadline.weight(.semibold))

            ForEach(ExportResolution.allCases) { resolution in
                resolutionRow(resolution)
            }
        }
    }

    private func resolutionRow(_ resolution: ExportResolution) -> some View {
        let isLocked = !viewModel.canSelectResolution(resolution, isPro: appState.isPro)
        let isSelected = viewModel.selectedResolution == resolution

        return Button {
            if isLocked {
                proGateFeature = resolution == .p4K ? "4K Export" : "1080p Export"
                proGateDescription = viewModel.lockReason(for: resolution, isPro: appState.isPro)
                    ?? "HD export requires \(AppBranding.proName)."
                showProGate = true
            } else {
                viewModel.selectedResolution = resolution
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
        .help(viewModel.lockReason(for: resolution, isPro: appState.isPro) ?? "")
    }

    private var missingRecordingView: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "No recording selected",
                systemImage: "film",
                description: Text("Choose a recording from the Dashboard or finish a new recording.")
            )
            Button("Go to Dashboard") {
                router.navigate(to: .dashboard)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func discardAndLeave() {
        viewModel.discardPending(appState: appState)
        viewModel.teardown()
        router.navigate(to: .dashboard)
    }
}

#Preview {
    ExportView()
        .environment(AppState())
        .environment(AppRouter())
}
