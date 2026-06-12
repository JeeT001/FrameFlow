//
//  EditorView.swift
//  FrameFlow
//

import SwiftUI

struct EditorView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = EditorViewModel()
    @State private var captionState = CaptionGenerationState.shared
    @State private var showProGate = false
    @State private var proGateFeature = ""
    @State private var proGateDescription = ""

    private var exportVM: ExportViewModel { viewModel.exportViewModel }
    private var captionVM: CaptionEditorViewModel { viewModel.captionViewModel }

    var body: some View {
        Group {
            if exportVM.recording == nil {
                missingRecordingView
            } else {
                editorLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Discard") {
                    discardAndLeave()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
            ToolbarItem(placement: .principal) {
                Text(exportVM.recording?.name ?? "Editor")
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    exportVM.isExportSheetPresented = true
                } label: {
                    Label("Export Video", systemImage: "square.and.arrow.up.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(exportVM.recording == nil)
            }
        }
        .sheet(isPresented: Binding(
            get: { exportVM.isExportSheetPresented },
            set: { exportVM.isExportSheetPresented = $0 }
        )) {
            EditorExportSheet(
                recordingName: exportVM.recording?.name,
                exportSummary: viewModel.exportSummary(
                    isPro: appState.isPro,
                    applyCaptions: exportVM.applyCaptions,
                    alsoSaveSRT: exportVM.alsoSaveSRT,
                    resolution: exportVM.selectedResolution
                ),
                exportVM: exportVM,
                isPro: appState.isPro,
                onExport: {
                    Task {
                        await viewModel.exportRecording(isPro: appState.isPro, appState: appState)
                    }
                },
                onShowProGate: { feature, description in
                    proGateFeature = feature
                    proGateDescription = description
                    showProGate = true
                }
            )
        }
        .onAppear {
            viewModel.load(appState: appState, isPro: appState.isPro)
        }
        .onDisappear {
            viewModel.teardown()
        }
        .proUpgradeSheet(
            isPresented: $showProGate,
            feature: proGateFeature,
            description: proGateDescription
        )
        .onChange(of: captionState.segments) { _, newSegments in
            guard captionVM.segments.isEmpty, !newSegments.isEmpty else { return }
            captionVM.segments = newSegments
            captionVM.sync(from: captionState)
        }
        .onChange(of: captionState.isTranscribing) { _, isTranscribing in
            if !isTranscribing {
                viewModel.onCaptionGenerationFinished(isPro: appState.isPro)
            }
        }
        .onChange(of: captionVM.videoDuration) { _, duration in
            viewModel.onVideoDurationLoaded(duration)
        }
        .onChange(of: exportVM.showSuccessAlert) { _, succeeded in
            if succeeded {
                exportVM.isExportSheetPresented = false
            }
        }
        .alert("Export complete", isPresented: Binding(
            get: { exportVM.showSuccessAlert },
            set: { exportVM.showSuccessAlert = $0 }
        )) {
            Button("Reveal in Finder") {
                exportVM.revealInFinder()
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
            if let url = exportVM.exportedURL {
                Text(url.path)
            }
        }
    }

    private var editorLayout: some View {
        EditorShellLayout {
            previewPanel
        } sidebar: {
            EditorInspectorPanel(
                viewModel: viewModel,
                captionVM: captionVM,
                captionState: captionState,
                isPro: appState.isPro,
                recording: exportVM.recording,
                sourceDurationSeconds: viewModel.sourceDurationSeconds,
                onShowProGate: { feature, description in
                    proGateFeature = feature
                    proGateDescription = description
                    showProGate = true
                },
                onGenerateCaptions: {
                    if let metadata = exportVM.recording {
                        captionState.begin(with: metadata)
                    }
                },
                onRetryTranscription: {
                    captionState.retry()
                }
            )
        }
        .focusable()
        .onKeyPress(.space) {
            viewModel.togglePlayback()
            return .handled
        }
    }

    private var isCaptionPlacementEditable: Bool {
        appState.isPro && !captionVM.segments.isEmpty && showCaptionOverlay
    }

    private var showCaptionPlacementChrome: Bool {
        isCaptionPlacementEditable && viewModel.selection.isCaptionRelated
    }

    private var activePlatformGuide: PlatformPreviewOverlay {
        guard exportVM.recording?.format == "9:16", !captionState.isTranscribing else { return .none }
        return viewModel.platformPreviewOverlay
    }

    private var previewPanel: some View {
        GeometryReader { geometry in
            let aspect = exportVM.recording?.previewAspectRatio ?? (16.0 / 9.0)
            let platformGuide = activePlatformGuide
            let hintReserve: CGFloat = 32
            let scrubberReserve: CGFloat = 52
            let videoAvailable = CGSize(
                width: geometry.size.width,
                height: max(120, geometry.size.height - hintReserve - scrubberReserve)
            )
            let fittedVideo = PreviewCanvasFitting.fittedSize(in: videoAvailable, aspectRatio: aspect)

            VStack(spacing: 8) {
                Spacer(minLength: 0)

                CaptionPreviewView(
                    player: captionVM.player,
                    currentTime: Binding(
                        get: { captionVM.currentPlaybackTime },
                        set: { viewModel.seekPreview(to: $0) }
                    ),
                    duration: viewModel.sourceDurationSeconds,
                    previewAspectRatio: aspect,
                    isPreviewPlaying: viewModel.isPreviewPlaying,
                    style: captionVM.selectedStyle,
                    displayText: showCaptionOverlay ? captionVM.overlayDisplayText : nil,
                    highlightedWord: showCaptionOverlay ? captionVM.highlightedWordInOverlay : nil,
                    isCaptionPlacementEditable: isCaptionPlacementEditable,
                    showsPlacementChrome: showCaptionPlacementChrome,
                    onSeek: { viewModel.seekPreview(to: $0) },
                    onTogglePlayback: { viewModel.togglePlayback() },
                    onCaptionVerticalOffsetChange: { captionVM.updateCaptionVerticalOffset($0) },
                    previewOverlay: {
                        GeometryReader { geo in
                            if platformGuide != .none {
                                PlatformSafeZoneOverlayView(
                                    platform: platformGuide,
                                    canvasSize: geo.size
                                )
                            }
                        }
                    }
                )
                .frame(width: fittedVideo.width)
                .clipped()

                previewHint(platformGuide: platformGuide)
                    .frame(width: fittedVideo.width, alignment: .leading)

                Spacer(minLength: 0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(minWidth: 280)
    }

    @ViewBuilder
    private func previewHint(platformGuide: PlatformPreviewOverlay) -> some View {
        if platformGuide != .none {
            Text("Platform guide is preview-only. Caption placement matches your export; avoid platform chrome when positioning.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        } else if isCaptionPlacementEditable {
            Text("Drag the caption box vertically to fine-tune placement.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var showCaptionOverlay: Bool {
        appState.isPro && !captionVM.segments.isEmpty
    }

    private var missingRecordingView: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "No recording selected",
                systemImage: "film.stack",
                description: Text("Finish a recording or choose one from the Dashboard.")
            )
            Button("Go to Dashboard") {
                router.navigate(to: .dashboard)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func discardAndLeave() {
        viewModel.discard(appState: appState)
        router.navigate(to: .dashboard)
    }
}

private extension EditorSelection {
    var isCaptionRelated: Bool {
        switch self {
        case .captions, .captionSegment:
            return true
        default:
            return false
        }
    }
}

#Preview {
    EditorView()
        .environment(AppState())
        .environment(AppRouter())
}
