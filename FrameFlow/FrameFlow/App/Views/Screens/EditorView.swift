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
        .navigationTitle("Editor")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Discard") {
                    discardAndLeave()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Export") {
                    Task { await viewModel.exportRecording(isPro: appState.isPro, appState: appState) }
                }
                .disabled(exportVM.isExporting || exportVM.recording == nil)
            }
        }
        .onAppear {
            viewModel.load(appState: appState, isPro: appState.isPro)
            ensureValidTabSelection()
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
        .onChange(of: appState.isPro) { _, isPro in
            ensureValidTabSelection(isPro: isPro)
        }
        .onChange(of: captionVM.videoDuration) { _, duration in
            viewModel.onVideoDurationLoaded(duration)
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
        VStack(spacing: 16) {
            GeometryReader { geometry in
                HStack(alignment: .top, spacing: 20) {
                    previewPanel
                        .frame(width: geometry.size.width * 0.55, height: geometry.size.height)

                    inspectorPanel
                        .frame(width: geometry.size.width * 0.45 - 20, height: geometry.size.height)
                }
            }

            EditorTimelineView(
                duration: viewModel.sourceDurationSeconds,
                trimStart: viewModel.trimStartSeconds,
                trimEnd: viewModel.trimEndSeconds,
                currentTime: captionVM.currentPlaybackTime,
                onTrimStartChange: { viewModel.updateTrimStart($0) },
                onTrimEndChange: { viewModel.updateTrimEnd($0) },
                onSeek: { captionVM.seek(to: $0) }
            )
            .frame(height: 80)
        }
        .padding(20)
    }

    private var isCaptionPlacementEditable: Bool {
        appState.isPro && viewModel.selectedTab == .captions && !captionVM.segments.isEmpty
    }

    private var previewPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let name = exportVM.recording?.name {
                Text(name)
                    .font(.headline)
                    .lineLimit(1)
            }

            let aspect = exportVM.recording?.previewAspectRatio ?? (16.0 / 9.0)

            CaptionPreviewView(
                player: captionVM.player,
                currentTime: Binding(
                    get: { captionVM.currentPlaybackTime },
                    set: { captionVM.currentPlaybackTime = $0 }
                ),
                duration: captionVM.videoDuration,
                style: captionVM.selectedStyle,
                displayText: showCaptionOverlay ? captionVM.overlayDisplayText : nil,
                highlightedWord: showCaptionOverlay ? captionVM.highlightedWordInOverlay : nil,
                isCaptionPlacementEditable: isCaptionPlacementEditable,
                onSeek: { captionVM.seek(to: $0) },
                onCaptionVerticalOffsetChange: { captionVM.updateCaptionVerticalOffset($0) }
            )
            .aspectRatio(aspect, contentMode: .fit)

            if isCaptionPlacementEditable {
                Text("Drag the caption box vertically to fine-tune placement.")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Button {
                captionVM.togglePlayback()
            } label: {
                Label("Play / Pause", systemImage: "playpause.fill")
            }
            .buttonStyle(.bordered)
        }
        .frame(minWidth: 360)
    }

    private var showCaptionOverlay: Bool {
        appState.isPro && viewModel.selectedTab != .export && !captionVM.segments.isEmpty
    }

    private var inspectorPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Section", selection: $viewModel.selectedTab) {
                ForEach(EditorViewModel.tabs(isPro: appState.isPro)) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch viewModel.selectedTab {
                case .edit:
                    editTab
                case .captions:
                    captionsTab
                case .export:
                    exportTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 320)
    }

    // MARK: - Tabs

    private var editTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Drag the timeline handles below to trim the start and end of your clip.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)

            if viewModel.hasTrimApplied {
                Label("Trimmed length: \(viewModel.formattedTrimDuration)", systemImage: "scissors")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var captionsTab: some View {
        if !appState.isPro {
            captionsProGate
        } else {
            captionsEditorContent
        }
    }

    private var captionsProGate: some View {
        ContentUnavailableView {
            Label("Pro feature", systemImage: "star.fill")
        } description: {
            Text("Auto captions and caption styling require FrameFlow Pro.")
        } actions: {
            Button("Upgrade") {
                proGateFeature = "Auto Captions"
                proGateDescription = "WhisperKit transcription and caption editing require FrameFlow Pro."
                showProGate = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private var captionsEditorContent: some View {
        if captionState.isTranscribing {
            VStack(alignment: .leading, spacing: 12) {
                Label("Generating captions…", systemImage: "waveform")
                    .font(.headline)

                ProgressView(value: captionState.progress)
                    .progressViewStyle(.linear)

                Text(captionState.statusMessage)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Text("First run may download the on-device Whisper model.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        } else if let error = captionState.errorMessage, captionState.segments.isEmpty, captionVM.segments.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Transcription failed", systemImage: "exclamationmark.triangle")
                    .font(.headline)
                    .foregroundStyle(AppColors.proGold)

                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .textSelection(.enabled)

                Button("Retry") {
                    captionState.retry()
                }
                .buttonStyle(.borderedProminent)
            }
        } else if captionState.segments.isEmpty && captionVM.segments.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("No captions yet")
                    .font(.headline)

                Text("Generate captions from speech in your recording.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)

                Button("Generate captions") {
                    if let metadata = exportVM.recording {
                        captionState.begin(with: metadata)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Caption style")
                        .font(.subheadline.weight(.semibold))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(CaptionStylePreset.allCases, id: \.self) { preset in
                                CaptionStyleCard(
                                    preset: preset,
                                    isSelected: captionVM.selectedStyle.preset == preset,
                                    onSelect: { captionVM.selectStyle(preset) }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Picker("Position", selection: captionPositionBinding) {
                        Text("Top").tag(CaptionVerticalPosition.top)
                        Text("Middle").tag(CaptionVerticalPosition.middle)
                        Text("Bottom").tag(CaptionVerticalPosition.bottom)
                    }
                    .pickerStyle(.segmented)

                    Text("Segments")
                        .font(.subheadline.weight(.semibold))

                    LazyVStack(spacing: 8) {
                        ForEach(captionVM.segments) { segment in
                            CaptionSegmentRow(
                                segment: segment,
                                isSelected: captionVM.selectedSegmentID == segment.id,
                                allowsTimeEditing: true,
                                onTextChange: { captionVM.updateSegmentText(id: segment.id, text: $0) },
                                onStartTimeChange: { captionVM.updateSegmentTimes(id: segment.id, start: $0, end: nil) },
                                onEndTimeChange: { captionVM.updateSegmentTimes(id: segment.id, start: nil, end: $0) },
                                onSelect: { captionVM.selectSegment(segment) }
                            )
                        }
                    }
                }
            }
        }
    }

    private var exportTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let recording = exportVM.recording {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 16) {
                            if viewModel.hasTrimApplied {
                                Text("Export length: \(viewModel.formattedTrimDuration)")
                                    .fontWeight(.medium)
                            } else {
                                Text(recording.formattedDuration)
                            }
                            Text(recording.formattedFileSize)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        if viewModel.hasTrimApplied {
                            Text("Source: \(recording.formattedDuration)")
                                .font(.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                    .font(.subheadline)
                }

                exportResolutionSection

                if exportVM.hasCaptionsAvailable {
                    Toggle("Include captions in export", isOn: Binding(
                        get: { exportVM.applyCaptions },
                        set: { exportVM.applyCaptions = $0 }
                    ))

                    if appState.isPro {
                        Toggle("Also save SRT file", isOn: Binding(
                            get: { exportVM.alsoSaveSRT },
                            set: { exportVM.alsoSaveSRT = $0 }
                        ))
                        Text("SRT saved next to exported MP4 in your save folder.")
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                if exportVM.showsCaptionsBadge {
                    Label("Captions included", systemImage: "captions.bubble.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.successGreen)
                }

                if !appState.isPro {
                    Label("Free exports include a FrameFlow watermark", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Text("Use the toolbar Export button when ready.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

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
            }
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
        let isLocked = !exportVM.canSelectResolution(resolution, isPro: appState.isPro)
        let isSelected = exportVM.selectedResolution == resolution

        return Button {
            if isLocked {
                proGateFeature = resolution == .p4K ? "4K Export" : "1080p Export"
                proGateDescription = exportVM.lockReason(for: resolution, isPro: appState.isPro)
                    ?? "HD export requires FrameFlow Pro."
                showProGate = true
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
        .help(exportVM.lockReason(for: resolution, isPro: appState.isPro) ?? "")
    }

    private var captionPositionBinding: Binding<CaptionVerticalPosition> {
        Binding(
            get: { captionVM.selectedStyle.verticalPosition },
            set: { captionVM.setPosition($0) }
        )
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

    private func ensureValidTabSelection(isPro: Bool? = nil) {
        let pro = isPro ?? appState.isPro
        let allowed = EditorViewModel.tabs(isPro: pro)
        if !allowed.contains(viewModel.selectedTab) {
            viewModel.selectedTab = .edit
        }
    }
}

#Preview {
    EditorView()
        .environment(AppState())
        .environment(AppRouter())
}
