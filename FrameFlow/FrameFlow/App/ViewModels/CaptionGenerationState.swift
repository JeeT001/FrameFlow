//
//  CaptionGenerationState.swift
//  FrameFlow
//

import Foundation

@MainActor
@Observable
final class CaptionGenerationState {
    static let shared = CaptionGenerationState()

    var isTranscribing = false
    var progress: Double = 0
    var statusMessage = ""
    var errorMessage: String?
    var segments: [CaptionSegment] = []
    var recordingID: UUID?
    var recordingMetadata: RecordingMetadata?
    var videoURL: URL?
    var sidecarURL: URL?
    var srtURL: URL?
    var burnedInVideoURL: URL?

    private var generationTask: Task<Void, Never>?

    private init() {}

    func begin(with metadata: RecordingMetadata) {
        generationTask?.cancel()
        resetForNewRun()
        recordingID = metadata.id
        recordingMetadata = metadata
        videoURL = URL(fileURLWithPath: metadata.filePath)
        isTranscribing = true
        statusMessage = "Preparing transcription…"

        generationTask = Task {
            await runGeneration()
        }
    }

    func retry() {
        guard let metadata = recordingMetadata else { return }
        begin(with: metadata)
    }

    func applySegments(_ updated: [CaptionSegment]) {
        segments = updated
    }

    func reset() {
        generationTask?.cancel()
        generationTask = nil
        isTranscribing = false
        progress = 0
        statusMessage = ""
        errorMessage = nil
        segments = []
        recordingID = nil
        recordingMetadata = nil
        videoURL = nil
        sidecarURL = nil
        srtURL = nil
        burnedInVideoURL = nil
    }

    private func resetForNewRun() {
        isTranscribing = false
        progress = 0
        statusMessage = ""
        errorMessage = nil
        segments = []
        sidecarURL = nil
        srtURL = nil
        burnedInVideoURL = nil
    }

    private func runGeneration() async {
        guard let videoURL, let recordingID else {
            errorMessage = "Recording file is unavailable."
            isTranscribing = false
            return
        }

        let engine = CaptionEngine.shared
        sidecarURL = engine.sidecarURLAdjacent(to: videoURL)
        srtURL = engine.srtURL(for: videoURL)
        burnedInVideoURL = engine.burnedInURL(for: videoURL)

        do {
            let generated = try await SecurityScopedFileAccess.withAccess(to: videoURL) {
                try await engine.generateCaptions(
                    for: videoURL,
                    recordingID: recordingID,
                    progress: { [weak self] value, message in
                        Task { @MainActor in
                            self?.progress = value
                            self?.statusMessage = message
                        }
                    }
                )
            }

            guard !Task.isCancelled else { return }

            segments = generated
            isTranscribing = false
            progress = 1
            statusMessage = "Captions ready (\(generated.count) segments)"
        } catch SecurityScopedFileAccess.AccessError.denied {
            guard !Task.isCancelled else { return }
            isTranscribing = false
            errorMessage = SecurityScopedFileAccess.accessDeniedMessage
            statusMessage = ""
        } catch {
            guard !Task.isCancelled else { return }
            isTranscribing = false
            errorMessage = error.localizedDescription
            statusMessage = ""
        }
    }
}
