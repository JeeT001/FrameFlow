//
//  RecordingDetailView.swift
//  FrameFlow
//

import SwiftUI

struct RecordingDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = RecordingDetailViewModel()

    @State private var showReexportConfirmation = false

    private let wideLayoutMinWidth: CGFloat = 700

    var body: some View {
        Group {
            if viewModel.recording == nil {
                missingView
            } else {
                detailContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Recording")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back") {
                    goToDashboard()
                }
            }
        }
        .onAppear {
            viewModel.load(recordingID: appState.detailRecordingID)
        }
        .onDisappear {
            appState.detailRecordingID = nil
        }
        .alert("Delete recording?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.deleteRecording() {
                        goToDashboard()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the video and related caption files from disk. This cannot be undone.")
        }
        .confirmationDialog(
            "Re-export original recording?",
            isPresented: $showReexportConfirmation,
            titleVisibility: .visible
        ) {
            Button("Re-export original") {
                performReexportOriginal()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This exports the full saved recording without editor changes " +
                "(trim, cuts, overlays, or imported audio). To export edits, finish from the Editor after recording."
            )
        }
    }

    private var detailContent: some View {
        GeometryReader { geometry in
            if geometry.size.width >= wideLayoutMinWidth {
                wideLayout
            } else {
                ScrollView {
                    narrowLayout
                }
            }
        }
    }

    private var wideLayout: some View {
        HStack(alignment: .top, spacing: 32) {
            thumbnailSection
                .frame(maxWidth: 480)

            VStack(alignment: .leading, spacing: 24) {
                detailSections
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .frame(maxWidth: 900)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var narrowLayout: some View {
        VStack(alignment: .leading, spacing: 24) {
            thumbnailSection
            detailSections
        }
        .padding(24)
        .frame(maxWidth: 720, alignment: .leading)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var detailSections: some View {
        renameSection

        if let error = viewModel.errorMessage {
            Text(error)
                .font(.subheadline)
                .foregroundStyle(AppColors.recRed)
        }

        metadataSection
        actionsSection
    }

    private var thumbnailSection: some View {
        let aspect = viewModel.recording?.previewAspectRatio ?? (16.0 / 9.0)

        return Button {
            viewModel.playInSystemPlayer()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.border)

                if let thumbnail = viewModel.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColors.textSecondary)
                }

                if viewModel.fileExistsOnDisk {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.35))
                }
            }
            .aspectRatio(aspect, contentMode: .fit)
            .frame(maxWidth: 480, maxHeight: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppColors.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.fileExistsOnDisk)
        .help("Open in default video player")
    }

    private var renameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 12) {
                TextField("Recording name", text: $viewModel.draftName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task { await viewModel.saveRename() }
                    }

                Button("Save") {
                    Task { await viewModel.saveRename() }
                }
                .disabled(viewModel.isSavingRename || !viewModel.fileExistsOnDisk)
            }

            Text("Saved as .mp4 in the same folder")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.subheadline.weight(.semibold))

            if let recording = viewModel.recording {
                metadataGrid(recording)
            }
        }
    }

    private func metadataGrid(_ recording: RecordingMetadata) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
            metadataRow("Recorded", recording.formattedDate)
            metadataRow("Duration", recording.formattedDuration)
            metadataRow("File size", recording.formattedFileSize)
            metadataRow("Resolution", recording.resolution)
            metadataRow("Format", recording.format)
            metadataRow("Layout", recording.layout.replacingOccurrences(of: "_", with: " ").capitalized)
            metadataRow("Windows", "\(recording.windowCount)")
            metadataRow("Audio", recording.audioMode.capitalized)
            metadataRow("Camera", recording.hasCamera ? "Yes" : "No")
            metadataRow("Captions", recording.hasCaptions ? "Yes" : "No")
        }
        .font(.subheadline)
    }

    private func metadataRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Actions")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 12) {
                Button {
                    viewModel.revealInFinder()
                } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                }
                .disabled(!viewModel.fileExistsOnDisk)

                Button {
                    showReexportConfirmation = true
                } label: {
                    Label("Re-export original…", systemImage: "square.and.arrow.up")
                }
                .disabled(viewModel.recording == nil)

                Button(role: .destructive) {
                    viewModel.showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(viewModel.isDeleting)
            }
        }
    }

    private var missingView: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "Recording not found",
                systemImage: "film",
                description: Text(viewModel.errorMessage ?? "Return to Home and choose a recording.")
            )
            Button("Back to Home") {
                goToDashboard()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func performReexportOriginal() {
        guard let recording = viewModel.recording else { return }
        stageCaptionsForExportIfAvailable(recording)
        appState.exportRecordingID = recording.id
        router.navigate(to: .export)
    }

    private func stageCaptionsForExportIfAvailable(_ recording: RecordingMetadata) {
        guard AppFeatureFlags.captionsEnabled else { return }
        let state = CaptionGenerationState.shared
        if state.recordingID == recording.id, !state.segments.isEmpty {
            appState.stageExportCaptions(
                recordingID: recording.id,
                segments: state.segments,
                leadingGap: recording.captionAudioLeadSeconds
            )
            return
        }

        let url = URL(fileURLWithPath: recording.filePath)
        let segments = (try? SecurityScopedFileAccess.withAccess(to: url) {
            try CaptionEngine.shared.loadCaptions(for: url, recordingID: recording.id)
        }) ?? []
        guard !segments.isEmpty else { return }
        appState.stageExportCaptions(
            recordingID: recording.id,
            segments: segments,
            leadingGap: recording.captionAudioLeadSeconds,
            style: CaptionEngine.shared.loadStyle(for: url, recordingID: recording.id)
        )
    }

    private func goToDashboard() {
        appState.detailRecordingID = nil
        router.navigate(to: .dashboard)
    }
}

#Preview {
    RecordingDetailView()
        .environment(AppState())
        .environment(AppRouter())
}
