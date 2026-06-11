//
//  EditorView.swift
//  FrameFlow
//

import AppKit
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
                captionVM.sync(from: captionState)
            }
        }
        .onChange(of: captionVM.videoDuration) { _, duration in
            viewModel.onVideoDurationLoaded(duration)
        }
        .onChange(of: captionVM.currentPlaybackTime) { _, _ in
            viewModel.onPreviewTimeTick()
        }
        .onChange(of: viewModel.project.importedAudioTracks) { _, _ in
            viewModel.refreshAudioPreview()
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

    // MARK: - Layout

    private var editorLayout: some View {
        EditorShellLayout {
            previewPanel
        } inspector: {
            EditorInspectorPanel(
                viewModel: viewModel,
                captionVM: captionVM,
                captionState: captionState,
                exportVM: exportVM,
                isPro: appState.isPro,
                recording: exportVM.recording,
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
        } tracks: {
            tracksPanel
        }
        .focusable()
        .onKeyPress(.upArrow) {
            viewModel.jumpToStart()
            return .handled
        }
        .onKeyPress(.downArrow) {
            viewModel.jumpToEnd()
            return .handled
        }
        .onKeyPress(.space) {
            viewModel.togglePlayback()
            return .handled
        }
        .onKeyPress(keys: [.init("b")], phases: .down) { press in
            guard press.modifiers.contains(.command) else { return .ignored }
            viewModel.splitAtPoint(viewModel.sourceTimeAtPlayhead())
            return .handled
        }
        .onKeyPress("s") {
            viewModel.razorModeActive.toggle()
            return .handled
        }
        .onKeyPress(.escape) {
            if viewModel.razorModeActive {
                viewModel.razorModeActive = false
                return .handled
            }
            return .ignored
        }
        .onAppear {
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
    }

    private var tracksPanel: some View {
        EditorTracksView(
            viewModel: viewModel,
            videoURL: URL(fileURLWithPath: exportVM.recording?.filePath ?? ""),
            duration: viewModel.sourceDurationSeconds,
            trimStart: viewModel.trimStartSeconds,
            trimEnd: viewModel.trimEndSeconds,
            exportDurationSeconds: viewModel.project.exportDurationSeconds,
            masterTimelineDuration: viewModel.project.masterTimelineDurationSeconds,
            videoExportDuration: viewModel.project.videoExportDurationSeconds,
            masterPlayheadSeconds: viewModel.masterPlayheadSeconds,
            hasAudioTimelineExtension: viewModel.project.hasAudioTimelineExtension,
            removedRanges: viewModel.editTimeline.removedRanges,
            splitPoints: viewModel.editTimeline.splitPoints,
            selectionStart: viewModel.selectionStartSeconds,
            selectionEnd: viewModel.selectionEndSeconds,
            currentTime: captionVM.currentPlaybackTime,
            currentExportTime: viewModel.masterPlayheadSeconds,
            imageClips: viewModel.imageClipLaneItems(),
            audioClips: viewModel.audioClipLaneItems(),
            videoClipLabel: exportVM.recording?.name ?? "Video",
            onTrimStartChange: { viewModel.updateTrimStart($0) },
            onTrimEndChange: { viewModel.updateTrimEnd($0) },
            onSelectionStartChange: { viewModel.updateSelectionStart($0) },
            onSelectionEndChange: { viewModel.updateSelectionEnd($0) },
            onSeek: { viewModel.seekPreviewOnMasterTimeline($0) },
            onImageStartChange: { viewModel.updateImageStart($1, id: $0) },
            onImageEndChange: { viewModel.updateImageEnd($1, id: $0) },
            onImageClipMove: { viewModel.updateImageClipMove(toStart: $1, id: $0) },
            onAudioStartChange: { viewModel.updateImportedAudioStart($1, id: $0) },
            onAudioEndChange: { viewModel.updateImportedAudioEnd($1, id: $0) },
            onAudioClipMove: { viewModel.updateImportedAudioClipMove(toStart: $1, id: $0) },
            onImportImage: { viewModel.importImage() },
            onImportAudio: { viewModel.importAudio() },
            onSelectOverlay: { viewModel.selectImageOverlay(id: $0) },
            onSelectAudio: { viewModel.selectImportedAudio(id: $0) },
            onSelectTimeline: { viewModel.selectTimeline() },
            onDeleteSelection: { viewModel.deleteSelection() },
            onClearDeletes: { viewModel.clearRemovedRegions() },
            canDeleteSelection: viewModel.canDeleteSelection,
            hasRemovedRegions: viewModel.hasRemovedRegions
        )
        .frame(height: viewModel.tracksPanelHeight)
    }

    private var selectedImageOverlayID: UUID? {
        viewModel.selectedImageOverlayID
    }

    private var isImageOverlayEditable: Bool {
        selectedImageOverlayID != nil
    }

    private var isCaptionPlacementEditable: Bool {
        appState.isPro
            && !captionVM.segments.isEmpty
            && showCaptionOverlay
            && selectedImageOverlayID == nil
    }

    private var showCaptionPlacementChrome: Bool {
        isCaptionPlacementEditable
            && (viewModel.inspectorMode == .captions || viewModel.selection.isCaptionRelated)
    }

    private var previewPanel: some View {
        GeometryReader { geometry in
            let aspect = exportVM.recording?.previewAspectRatio ?? (16.0 / 9.0)
            let hintReserve: CGFloat = 32
            let scrubberReserve: CGFloat = 130
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
                        get: { viewModel.masterPlayheadSeconds },
                        set: { viewModel.seekPreviewOnMasterTimeline($0) }
                    ),
                    duration: viewModel.project.masterTimelineDurationSeconds,
                    previewAspectRatio: aspect,
                    videoEndSeconds: viewModel.project.hasAudioTimelineExtension
                        ? viewModel.project.videoExportDurationSeconds
                        : nil,
                    isPlayheadPastVideo: viewModel.isPlayheadInAudioOnlyRegion,
                    isPreviewPlaying: viewModel.isPreviewPlaying,
                    style: captionVM.selectedStyle,
                    displayText: showCaptionOverlay ? captionVM.overlayDisplayText : nil,
                    highlightedWord: showCaptionOverlay ? captionVM.highlightedWordInOverlay : nil,
                    isCaptionPlacementEditable: isCaptionPlacementEditable,
                    showsPlacementChrome: showCaptionPlacementChrome,
                    onSeek: { viewModel.seekPreviewOnMasterTimeline($0) },
                    onTogglePlayback: { viewModel.togglePlayback() },
                    onCaptionVerticalOffsetChange: { captionVM.updateCaptionVerticalOffset($0) },
                    onSkipBack: { viewModel.jumpToStart() },
                    onSlowMotion: { viewModel.showComingSoon("Slow motion") },
                    onStop: { viewModel.stopPreview() },
                    onSetInPoint: { viewModel.setInPointAtPlayhead() },
                    onSetOutPoint: { viewModel.setOutPointAtPlayhead() },
                    onSnapshot: {
                        Task { await viewModel.snapshotCurrentFrame() }
                    },
                    onFullscreen: { viewModel.showComingSoon("Fullscreen") },
                    previewOverlay: {
                        ForEach(viewModel.project.imageOverlays) { overlay in
                            let isSelected = viewModel.selectedImageOverlayID == overlay.id
                            let isVisible = overlay.contains(playhead: captionVM.currentPlaybackTime)
                            if isVisible || isSelected {
                                EditorImageOverlayPreview(
                                    overlay: overlay,
                                    containerAspect: aspect,
                                    currentPlayhead: captionVM.currentPlaybackTime,
                                    isEditable: isSelected && isImageOverlayEditable,
                                    onPositionChange: { viewModel.updateImagePosition(x: $0, y: $1, id: overlay.id) },
                                    onSizeChange: { viewModel.updateImageWidth($0, id: overlay.id) },
                                    onSelect: { viewModel.selectImageOverlay(id: overlay.id) }
                                )
                            }
                        }
                    }
                )
                .frame(width: fittedVideo.width)
                .clipped()

                previewHint
                    .frame(width: fittedVideo.width, alignment: .leading)

                Spacer(minLength: 0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(minWidth: 280)
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.project.imageOverlays.isEmpty {
                viewModel.clearSelection()
            }
        }
    }

    @ViewBuilder
    private var previewHint: some View {
        if viewModel.isPlayheadInAudioOnlyRegion {
            Text(
                viewModel.isPreviewPlaying
                    ? "Playing imported audio — video has ended."
                    : "Past video end — press Play to hear imported audio."
            )
            .font(.caption)
            .foregroundStyle(AppColors.primary)
        } else if isCaptionPlacementEditable {
            Text("Drag the caption box vertically to fine-tune placement.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        } else if isImageOverlayEditable {
            Text("Drag to move the image · use the corner handle or Size slider to resize.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        } else if viewModel.project.hasAudioTimelineExtension {
            Text("Playback continues on imported audio after the video ends.")
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
