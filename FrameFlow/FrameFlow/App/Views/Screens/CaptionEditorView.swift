//
//  CaptionEditorView.swift
//  FrameFlow
//

import AVFoundation
import SwiftUI

struct CaptionEditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var captionState = CaptionGenerationState.shared
    @State private var viewModel = CaptionEditorViewModel()
    @State private var showProGate = false

    var body: some View {
        Group {
            if !appState.isPro {
                proUpgradeView
            } else if captionState.isTranscribing {
                transcribingView
            } else if let error = captionState.errorMessage, captionState.segments.isEmpty {
                transcriptionErrorView(error)
            } else if captionState.segments.isEmpty && viewModel.segments.isEmpty {
                emptyStateView
            } else {
                editorLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Caption Editor")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Skip Captions") {
                    skipCaptions()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Export Video") {
                    openExportScreen()
                }
                .disabled(captionState.recordingID == nil)
            }
        }
        .onAppear {
            viewModel.sync(from: captionState)
        }
        .onDisappear {
            viewModel.teardown()
        }
        .proUpgradeSheet(
            isPresented: $showProGate,
            feature: "Auto Captions",
            description: "WhisperKit transcription and the caption editor require FrameFlow Pro."
        )
        .onChange(of: captionState.segments) { _, newSegments in
            guard viewModel.segments.isEmpty, !newSegments.isEmpty else { return }
            viewModel.segments = newSegments
            viewModel.sync(from: captionState)
        }
        .onChange(of: captionState.isTranscribing) { _, isTranscribing in
            if !isTranscribing {
                viewModel.sync(from: captionState)
            }
        }
        .alert("Export complete", isPresented: $viewModel.showExportSuccessAlert) {
            Button("Reveal in Finder") {
                viewModel.revealExportedFiles()
            }
            Button("Dashboard") {
                router.navigate(to: .dashboard)
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportSuccessMessage)
        }
    }

    // MARK: - Editor layout

    private var editorLayout: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 20) {
                leftPreviewPanel
                    .frame(width: geometry.size.width * 0.4, height: geometry.size.height)

                rightEditorPanel
                    .frame(width: geometry.size.width * 0.6 - 20, height: geometry.size.height)
            }
        }
        .padding(20)
    }

    private var leftPreviewPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let name = captionState.recordingMetadata?.name {
                Text(name)
                    .font(.headline)
                    .lineLimit(1)
            }

            if captionState.videoURL != nil {
                CaptionPreviewView(
                    player: viewModel.player,
                    currentTime: $viewModel.currentPlaybackTime,
                    duration: viewModel.videoDuration,
                    style: viewModel.selectedStyle,
                    displayText: viewModel.overlayDisplayText,
                    highlightedWord: viewModel.highlightedWordInOverlay,
                    onSeek: { viewModel.seek(to: $0) }
                )
                .onAppear {
                    if viewModel.player.currentItem == nil {
                        viewModel.sync(from: captionState)
                    }
                }

                Button {
                    viewModel.togglePlayback()
                } label: {
                    Label("Play / Pause", systemImage: "playpause.fill")
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(minWidth: 320)
    }

    private var rightEditorPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Caption style")
                .font(.subheadline.weight(.semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CaptionStylePreset.allCases, id: \.self) { preset in
                        CaptionStyleCard(
                            preset: preset,
                            isSelected: viewModel.selectedStyle.preset == preset,
                            onSelect: { viewModel.selectStyle(preset) }
                        )
                    }
                }
                .padding(.vertical, 4)
            }

            Text("Segments")
                .font(.subheadline.weight(.semibold))

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.segments) { segment in
                        CaptionSegmentRow(
                            segment: segment,
                            isSelected: viewModel.selectedSegmentID == segment.id,
                            onTextChange: { viewModel.updateSegmentText(id: segment.id, text: $0) },
                            onSelect: { viewModel.selectSegment(segment) }
                        )
                    }
                }
            }
            .frame(maxHeight: .infinity)

            bottomControls
        }
        .frame(minWidth: 380)
    }

    private var bottomControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let exportError = viewModel.exportError {
                Text(exportError)
                    .font(.caption)
                    .foregroundStyle(AppColors.recRed)
            }

            HStack(spacing: 16) {
                Picker("Position", selection: positionBinding) {
                    Text("Top").tag(CaptionVerticalPosition.top)
                    Text("Middle").tag(CaptionVerticalPosition.middle)
                    Text("Bottom").tag(CaptionVerticalPosition.bottom)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)

                Picker("Export", selection: $viewModel.exportFormat) {
                    ForEach(CaptionEditorViewModel.CaptionExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .frame(width: 140)
            }

            if viewModel.isExporting {
                ProgressView(value: viewModel.exportProgress)
                Text(viewModel.exportStatusMessage)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Button {
                Task { await viewModel.exportCaptions() }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isExporting || viewModel.segments.isEmpty)
        }
        .padding(.top, 8)
    }

    private var positionBinding: Binding<CaptionVerticalPosition> {
        Binding(
            get: { viewModel.selectedStyle.verticalPosition },
            set: { viewModel.setPosition($0) }
        )
    }

    // MARK: - Alternate states

    private var transcribingView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let name = captionState.recordingMetadata?.name {
                Text(name)
                    .font(.title2.weight(.semibold))
            }

            Label("Generating captions…", systemImage: "waveform")
                .font(.headline)

            ProgressView(value: captionState.progress)
                .progressViewStyle(.linear)

            Text(captionState.statusMessage)
                .foregroundStyle(AppColors.textSecondary)

            Text("First run may download the on-device Whisper model.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func transcriptionErrorView(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Transcription failed", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(AppColors.proGold)

            Text(error)
                .foregroundStyle(AppColors.textSecondary)
                .textSelection(.enabled)

            Button("Retry") {
                captionState.retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var proUpgradeView: some View {
        ContentUnavailableView {
            Label("Pro feature", systemImage: "star.fill")
        } description: {
            Text("Auto captions and the caption editor require FrameFlow Pro.")
        } actions: {
            Button("Upgrade") {
                showProGate = true
            }
            .buttonStyle(.borderedProminent)

            Button("Skip to Export") {
                skipCaptions()
            }
        }
        .padding()
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No captions yet",
            systemImage: "captions.bubble",
            description: Text("Record with speech as a Pro user, or retry transcription.")
        )
    }

    private var exportSuccessMessage: String {
        viewModel.exportedPaths.map(\.path).joined(separator: "\n")
    }

    private func skipCaptions() {
        viewModel.teardown()
        captionState.reset()
        if let id = appState.pendingRecording?.id ?? captionState.recordingID {
            appState.exportRecordingID = id
        }
        router.navigate(to: .export)
    }

    private func openExportScreen() {
        appState.exportRecordingID = captionState.recordingID
        router.navigate(to: .export)
    }
}

#Preview {
    CaptionEditorView()
        .environment(AppRouter())
        .environment(AppState())
}
