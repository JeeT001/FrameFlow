//
//  EditorInspectorPanel.swift
//  FrameFlow
//

import SwiftUI

struct EditorInspectorPanel: View {
    @Bindable var viewModel: EditorViewModel
    @Bindable var captionVM: CaptionEditorViewModel
    let captionState: CaptionGenerationState
    let isPro: Bool
    let recording: RecordingMetadata?
    let sourceDurationSeconds: Double
    let onShowProGate: (String, String) -> Void
    let onGenerateCaptions: () -> Void
    let onRetryTranscription: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let recording {
                    videoInfoSection(recording: recording)
                    if recording.format == "9:16" {
                        sectionDivider
                        platformPreviewSection
                    }
                    sectionDivider
                }

                captionsSection
                sectionDivider

                exportHintSection
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 280)
    }

    private var sectionDivider: some View {
        Divider()
            .padding(.vertical, 12)
    }

    private func inspectorSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
            .tracking(1)
    }

    private func videoInfoSection(recording: RecordingMetadata) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            inspectorSectionHeader("Video info")
            EditorClipInfoSection(
                recording: recording,
                sourceDurationSeconds: sourceDurationSeconds
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var platformPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            inspectorSectionHeader("Platform preview")

            Picker("Platform preview", selection: $viewModel.platformPreviewOverlay) {
                ForEach(PlatformPreviewOverlay.allCases) { platform in
                    Text(platform.pickerTitle).tag(platform)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()

            Text("Guide only — not included in your video")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, 16)
    }

    private var captionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            inspectorSectionHeader("Captions")

            if !isPro {
                captionsProGate
            } else {
                captionsEditorContent
            }
        }
        .padding(.horizontal, 16)
    }

    private var exportHintSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            inspectorSectionHeader("Export")
            Text("Use Export Video in the toolbar to save your recording. The full clip is exported as captured.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var captionsProGate: some View {
        ContentUnavailableView {
            Label("Pro feature", systemImage: "lock.fill")
        } description: {
            Text("Auto captions and caption styling require \(AppBranding.proName).")
        } actions: {
            Button("Upgrade to Pro") {
                onShowProGate(
                    "Auto Captions",
                    "WhisperKit transcription and caption editing require \(AppBranding.proName)."
                )
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
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
                        ForEach(CaptionStylePreset.selectablePresets, id: \.self) { preset in
                            CaptionStyleCard(
                                preset: preset,
                                isSelected: captionVM.selectedStyle.preset.pickerSelectionEquivalent == preset,
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
