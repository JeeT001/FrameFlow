//
//  EditorInspectorPanel.swift
//  FrameFlow
//

import SwiftUI

struct EditorInspectorPanel: View {
    @Bindable var viewModel: EditorViewModel
    @Bindable var captionVM: CaptionEditorViewModel
    let captionState: CaptionGenerationState
    let exportVM: ExportViewModel
    let isPro: Bool
    let recording: RecordingMetadata?
    let onShowProGate: (String, String) -> Void
    let onGenerateCaptions: () -> Void
    let onRetryTranscription: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            inspectorModePicker
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ScrollView {
                Group {
                    if viewModel.inspectorMode == .captions {
                        captionsContent
                    } else {
                        editModeContent
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(minWidth: 280)
    }

    private var inspectorModePicker: some View {
        Picker("Inspector", selection: $viewModel.inspectorMode) {
            ForEach(EditorInspectorMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: viewModel.inspectorMode) { _, newMode in
            if newMode == .captions {
                if isPro {
                    viewModel.selectCaptions()
                } else {
                    viewModel.inspectorMode = .edit
                    onShowProGate(
                        "Auto Captions",
                        "WhisperKit transcription and caption editing require FrameFlow Pro."
                    )
                }
            } else if viewModel.selection == .captions || viewModel.selection.isCaptionRelated {
                viewModel.selection = .timeline
            }
        }
    }

    private func inspectorSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(1)
    }

    @ViewBuilder
    private var editModeContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let recording {
                VStack(alignment: .leading, spacing: 12) {
                    inspectorSectionHeader("Project")
                    EditorClipInfoSection(
                        recording: recording,
                        sourceDurationSeconds: viewModel.sourceDurationSeconds,
                        exportDurationSeconds: viewModel.project.exportDurationSeconds,
                        masterTimelineDurationSeconds: viewModel.project.masterTimelineDurationSeconds,
                        hasTrimApplied: viewModel.hasTrimApplied,
                        hasRemovedRegions: viewModel.hasRemovedRegions,
                        formattedExportDuration: viewModel.formattedExportDuration
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)

                Divider()
            }

            if let importError = viewModel.importError {
                Text(importError)
                    .font(.caption)
                    .foregroundStyle(AppColors.recRed)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }

            switch viewModel.selection {
            case .imageOverlay:
                imageOverlaySection
            case .importedAudio:
                importedAudioSection
            case .timeline, .captionSegment, .captions:
                timelineSection
            case .none:
                idleEditHints
            }
        }
    }

    private var idleEditHints: some View {
        VStack(alignment: .leading, spacing: 10) {
            inspectorSectionHeader("Clip properties")

            Text("Select an image, audio clip, or timeline region to edit it here. Use Import Image or Import Audio in the timeline toolbar.")
                .font(.caption)
                .foregroundStyle(.secondary)

            removedRangesSection

            Text("Shortcuts: Space play/pause · S split at playhead")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            inspectorSectionHeader("Timeline")

            Text("Drag trim handles, select a region, then Delete. Split at playhead with S.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.hasTrimApplied || viewModel.hasRemovedRegions {
                Label("Export length: \(viewModel.formattedExportDuration)", systemImage: "scissors")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                if let removed = viewModel.formattedRemovedSpan {
                    Text("Removed: \(removed)")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Button("Select region") {
                viewModel.beginSelectionIfNeeded()
            }
            .buttonStyle(.bordered)

            removedRangesSection
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var removedRangesSection: some View {
        let ranges = viewModel.editTimeline.sortedRemovedRanges
        if !ranges.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Removed sections")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)

                ForEach(Array(ranges.enumerated()), id: \.offset) { index, range in
                    HStack {
                        Text(
                            "\(TrimHelpers.formatTimelineTime(range.startSeconds))–" +
                            "\(TrimHelpers.formatTimelineTime(range.endSeconds)) " +
                            "(\(TrimHelpers.formatTimelineTime(range.duration)))"
                        )
                        .font(.caption.monospacedDigit())

                        Spacer()

                        Button {
                            viewModel.removeRemovedRange(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppColors.textSecondary)
                        .help("Remove this cut")
                    }
                }
            }
        }
    }

    private var imageOverlaySection: some View {
        Group {
            if let overlay = viewModel.selectedImageOverlay, let overlayID = viewModel.selectedImageOverlayID {
                VStack(alignment: .leading, spacing: 12) {
                    inspectorSectionHeader("Image overlay")

                    layerPicker(
                        title: "Image layers",
                        items: viewModel.project.imageOverlays.map { ($0.id, $0.fileURL.lastPathComponent) },
                        selectedID: overlayID,
                        onSelect: { viewModel.selectImageOverlay(id: $0) }
                    )

                    HStack {
                        Text("Image overlay")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Button("Remove", role: .destructive) {
                            viewModel.removeImageOverlay(id: overlayID)
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                    }

                    Text(overlay.fileURL.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)

                    Text(
                        "Visible: \(TrimHelpers.formatTimelineTime(overlay.startSeconds))–" +
                        "\(TrimHelpers.formatTimelineTime(overlay.endSeconds)) " +
                        "(\(TrimHelpers.formatTimelineTime(overlay.duration)))"
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppColors.textSecondary)

                    if !viewModel.isImageVisibleAtPlayhead {
                        Text("Image hidden at playhead — scrub into the highlighted range.")
                            .font(.caption)
                            .foregroundStyle(AppColors.proGold)
                    }

                    HStack {
                        Text("In")
                        Slider(value: Binding(
                            get: { overlay.startSeconds },
                            set: { viewModel.updateImageStart($0, id: overlayID) }
                        ), in: viewModel.trimStartSeconds...max(
                            viewModel.trimStartSeconds,
                            overlay.endSeconds - EditTimelineModel.minimumSpanSeconds
                        ))
                    }

                    HStack {
                        Text("Out")
                        Slider(value: Binding(
                            get: { overlay.endSeconds },
                            set: { viewModel.updateImageEnd($0, id: overlayID) }
                        ), in: min(
                            overlay.startSeconds + EditTimelineModel.minimumSpanSeconds,
                            viewModel.trimEndSeconds
                        )...viewModel.trimEndSeconds)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Opacity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: Binding(
                            get: { overlay.opacity },
                            set: { viewModel.updateImageOpacity($0, id: overlayID) }
                        ), in: 0...1)
                        .controlSize(.small)
                    }

                    HStack {
                        Text("X")
                        Slider(value: Binding(
                            get: { overlay.normalizedCenterX },
                            set: { viewModel.updateImagePosition(x: $0, y: overlay.normalizedCenterY, id: overlayID) }
                        ), in: 0...1)
                    }

                    HStack {
                        Text("Y")
                        Slider(value: Binding(
                            get: { overlay.normalizedCenterY },
                            set: { viewModel.updateImagePosition(x: overlay.normalizedCenterX, y: $0, id: overlayID) }
                        ), in: 0...1)
                    }

                    HStack {
                        Text("Size")
                        Slider(value: Binding(
                            get: { overlay.normalizedWidth },
                            set: { viewModel.updateImageWidth($0, id: overlayID) }
                        ), in: EditorImageOverlay.normalizedWidthRange)
                    }

                    Text("Drag clip on timeline or preview to reposition.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)

                Divider()
            }
        }
    }

    private var importedAudioSection: some View {
        Group {
            if let audio = viewModel.selectedImportedAudio, let audioID = viewModel.selectedImportedAudioID {
                VStack(alignment: .leading, spacing: 12) {
                    inspectorSectionHeader("Imported audio")

                    layerPicker(
                        title: "Audio layers",
                        items: viewModel.project.importedAudioTracks.map { ($0.id, $0.fileURL.lastPathComponent) },
                        selectedID: audioID,
                        onSelect: { viewModel.selectImportedAudio(id: $0) }
                    )

                    HStack {
                        Text("Imported audio")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Button("Remove", role: .destructive) {
                            viewModel.removeImportedAudio(id: audioID)
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                    }

                    Text(audio.fileURL.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)

                    Text(
                        "Timeline: \(TrimHelpers.formatTimelineTime(audio.timelineStartSeconds))–" +
                        "\(TrimHelpers.formatTimelineTime(audio.timelineEndSeconds)) " +
                        "(\(TrimHelpers.formatTimelineTime(audio.playDuration)))"
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppColors.textSecondary)

                    Text(
                        "Source trim: \(TrimHelpers.formatTimelineTime(audio.sourceTrimStartSeconds))–" +
                        "\(TrimHelpers.formatTimelineTime(audio.sourceTrimEndSeconds)) " +
                        "(\(TrimHelpers.formatTimelineTime(audio.sourceTrimDuration)))"
                    )
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppColors.textSecondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Volume")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: Binding(
                            get: { audio.volume },
                            set: { viewModel.updateImportedAudioVolume($0, id: audioID) }
                        ), in: 0...1)
                        .controlSize(.small)
                    }

                    Text("Timeline position")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.textSecondary)

                    HStack {
                        Text("In")
                        Slider(value: Binding(
                            get: { audio.timelineStartSeconds },
                            set: { viewModel.updateImportedAudioStart($0, id: audioID) }
                        ), in: 0...max(
                            0,
                            audio.timelineEndSeconds - EditTimelineModel.minimumSpanSeconds
                        ))
                    }

                    HStack {
                        Text("Out")
                        Slider(value: Binding(
                            get: { audio.timelineEndSeconds },
                            set: { viewModel.updateImportedAudioEnd($0, id: audioID) }
                        ), in: (audio.timelineStartSeconds + EditTimelineModel.minimumSpanSeconds)...(
                            audio.timelineStartSeconds + audio.sourceTrimDuration
                        ))
                    }

                    Text("Source file trim")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.textSecondary)

                    HStack {
                        Text("Src In")
                        Slider(value: Binding(
                            get: { audio.sourceTrimStartSeconds },
                            set: { viewModel.updateImportedAudioSourceTrimStart($0, id: audioID) }
                        ), in: 0...max(
                            0,
                            audio.sourceTrimEndSeconds - EditTimelineModel.minimumSpanSeconds
                        ))
                    }

                    HStack {
                        Text("Src Out")
                        Slider(value: Binding(
                            get: { audio.sourceTrimEndSeconds },
                            set: { viewModel.updateImportedAudioSourceTrimEnd($0, id: audioID) }
                        ), in: (audio.sourceTrimStartSeconds + EditTimelineModel.minimumSpanSeconds)...audio.sourceDurationSeconds)
                    }

                    Text("Import uses the full audio length — the timeline extends when audio is longer than video.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)

                Divider()
            }
        }
    }

    private func layerPicker(
        title: String,
        items: [(UUID, String)],
        selectedID: UUID,
        onSelect: @escaping (UUID) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if items.count > 1 {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(items, id: \.0) { id, name in
                            Button {
                                onSelect(id)
                            } label: {
                                Text((name as NSString).lastPathComponent)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        selectedID == id
                                            ? AppColors.primary.opacity(0.2)
                                            : AppColors.border.opacity(0.2),
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var captionsContent: some View {
        if !isPro {
            captionsProGate
        } else {
            captionsEditorContent
        }
    }

    private var captionsProGate: some View {
        ContentUnavailableView {
            Label("Pro feature", systemImage: "lock.fill")
        } description: {
            Text("Auto captions and caption styling require FrameFlow Pro.")
        } actions: {
            Button("Upgrade to Pro") {
                onShowProGate(
                    "Auto Captions",
                    "WhisperKit transcription and caption editing require FrameFlow Pro."
                )
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
            }
        } else if let error = captionState.errorMessage,
                  captionState.segments.isEmpty,
                  captionVM.segments.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Transcription failed", systemImage: "exclamationmark.triangle")
                    .font(.headline)
                    .foregroundStyle(AppColors.proGold)

                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .textSelection(.enabled)

                Button("Retry", action: onRetryTranscription)
                    .buttonStyle(.borderedProminent)
            }
        } else if captionState.segments.isEmpty && captionVM.segments.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("No captions yet")
                    .font(.headline)

                Text("Generate captions from speech in your recording.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)

                Button("Generate captions", action: onGenerateCaptions)
                    .buttonStyle(.borderedProminent)
            }
        } else {
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

                Text("Drag the caption on the preview to fine-tune placement.")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)

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
                            onSelect: {
                                viewModel.selectCaptionSegment(segment.id)
                                captionVM.selectSegment(segment)
                            }
                        )
                    }
                }
            }
        }
    }

    private var captionPositionBinding: Binding<CaptionVerticalPosition> {
        Binding(
            get: { captionVM.selectedStyle.verticalPosition },
            set: { captionVM.setPosition($0) }
        )
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
