//
//  RecordingDetailView.swift
//  FrameFlow
//

import SwiftUI

struct RecordingDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = RecordingDetailViewModel()

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
    }

    private var detailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                thumbnailSection

                renameSection

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                metadataSection

                actionsSection
            }
            .padding(24)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private var thumbnailSection: some View {
        Button {
            viewModel.playInSystemPlayer()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondary.opacity(0.15))
                    .aspectRatio(16 / 9, contentMode: .fit)

                if let thumbnail = viewModel.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                }

                if viewModel.fileExistsOnDisk {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 52))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.35))
                        .shadow(radius: 4)
                }
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
                .foregroundStyle(.secondary)
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
                    reexport()
                } label: {
                    Label("Re-export", systemImage: "square.and.arrow.up")
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

    private func reexport() {
        guard let id = viewModel.recording?.id else { return }
        appState.exportRecordingID = id
        router.navigate(to: .export)
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
