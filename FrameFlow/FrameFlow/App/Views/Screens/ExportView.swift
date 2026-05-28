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
            viewModel.load(exportRecordingID: appState.exportRecordingID)
            if !appState.isPro {
                viewModel.selectedResolution = .p720
            }
        }
        .onDisappear {
            viewModel.teardown()
        }
        .alert("Export complete", isPresented: $viewModel.showSuccessAlert) {
            Button("Reveal in Finder") {
                viewModel.revealInFinder()
            }
            Button("Dashboard") {
                appState.exportRecordingID = nil
                router.navigate(to: .dashboard)
            }
            Button("OK", role: .cancel) {
                appState.exportRecordingID = nil
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
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }

                VideoPlayer(player: viewModel.player)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 10))

                resolutionSection

                if viewModel.hasCaptionsAvailable {
                    Toggle("Include captions in export", isOn: $viewModel.applyCaptions)
                }

                if viewModel.showsCaptionsBadge {
                    Label("Captions included", systemImage: "captions.bubble.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                }

                if !appState.isPro {
                    Label("Free exports include a FrameFlow watermark", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let exportError = viewModel.exportError {
                    Text(exportError)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                if viewModel.isExporting {
                    ProgressView(value: viewModel.progress)
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task { await viewModel.export(isPro: appState.isPro) }
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
            guard !isLocked else { return }
            viewModel.selectedResolution = resolution
        } label: {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)

                Text(resolution.displayName)
                    .foregroundStyle(.primary)

                Spacer()

                if isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
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
        viewModel.teardown()
        appState.exportRecordingID = nil
        router.navigate(to: .dashboard)
    }
}

#Preview {
    ExportView()
        .environment(AppState())
        .environment(AppRouter())
}
