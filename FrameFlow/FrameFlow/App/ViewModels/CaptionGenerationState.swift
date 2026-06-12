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
    private var elapsedTimerTask: Task<Void, Never>?
    private var generationRunID: UInt64 = 0
    private var lastProgressReportDate: Date?
    private var generationStartedAt: Date?
    private var baseStatusMessage = ""
    private let progressThrottleInterval: TimeInterval = 0.2

    private init() {}

    func begin(with metadata: RecordingMetadata) {
        generationTask?.cancel()
        stopElapsedTimer()
        generationRunID &+= 1
        let runID = generationRunID
        resetForNewRun()
        recordingID = metadata.id
        recordingMetadata = metadata
        videoURL = URL(fileURLWithPath: metadata.filePath)
        isTranscribing = true
        generationStartedAt = Date()
        baseStatusMessage = "Preparing transcription…"
        statusMessage = baseStatusMessage
        startElapsedTimer(runID: runID)

        let capturedVideoURL = videoURL
        let capturedRecordingID = recordingID

        generationTask = Task.detached(priority: .userInitiated) {
            await Self.runGeneration(
                runID: runID,
                videoURL: capturedVideoURL,
                recordingID: capturedRecordingID
            )
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
        stopElapsedTimer()
        generationRunID &+= 1
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
        lastProgressReportDate = nil
        generationStartedAt = nil
        baseStatusMessage = ""
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
        lastProgressReportDate = nil
        generationStartedAt = nil
        baseStatusMessage = ""
    }

    private func startElapsedTimer(runID: UInt64) {
        elapsedTimerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.refreshElapsedStatus(runID: runID)
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimerTask?.cancel()
        elapsedTimerTask = nil
    }

    private func refreshElapsedStatus(runID: UInt64) {
        guard runID == generationRunID, isTranscribing, !baseStatusMessage.isEmpty else { return }
        guard let started = generationStartedAt else { return }
        let elapsed = Int(Date().timeIntervalSince(started))
        guard elapsed >= 3 else { return }
        statusMessage = "\(baseStatusMessage) (\(elapsed)s)"
    }

    fileprivate func reportProgress(runID: UInt64, value: Double, message: String, force: Bool = false) {
        guard runID == generationRunID, isTranscribing else { return }

        baseStatusMessage = message
        let clampedValue = max(progress, min(value, 1.0))
        let now = Date()
        if !force,
           let lastReport = lastProgressReportDate,
           now.timeIntervalSince(lastReport) < progressThrottleInterval,
           clampedValue <= progress + 0.02 {
            refreshElapsedStatus(runID: runID)
            return
        }

        lastProgressReportDate = now
        progress = clampedValue
        refreshElapsedStatus(runID: runID)
    }

    private func finishCancelled(runID: UInt64) {
        guard runID == generationRunID, Task.isCancelled else { return }
        stopElapsedTimer()
        isTranscribing = false
        statusMessage = ""
        baseStatusMessage = ""
    }

    private nonisolated static func runGeneration(
        runID: UInt64,
        videoURL: URL?,
        recordingID: UUID?
    ) async {
        guard let videoURL, let recordingID else {
            await MainActor.run {
                let state = CaptionGenerationState.shared
                guard runID == state.generationRunID else { return }
                state.errorMessage = "Recording file is unavailable."
                state.stopElapsedTimer()
                state.isTranscribing = false
            }
            return
        }

        let engine = CaptionEngine.shared
        await MainActor.run {
            let state = CaptionGenerationState.shared
            guard runID == state.generationRunID else { return }
            state.sidecarURL = engine.sidecarURLAdjacent(to: videoURL)
            state.srtURL = engine.srtURL(for: videoURL)
            state.burnedInVideoURL = engine.burnedInURL(for: videoURL)
        }

        do {
            let generated = try await SecurityScopedFileAccess.withAccess(to: videoURL) {
                try await engine.generateCaptions(
                    for: videoURL,
                    recordingID: recordingID,
                    burnIn: false,
                    progress: { value, message in
                        Task { @MainActor in
                            CaptionGenerationState.shared.reportProgress(runID: runID, value: value, message: message)
                        }
                    }
                )
            }

            if Task.isCancelled {
                await MainActor.run {
                    CaptionGenerationState.shared.finishCancelled(runID: runID)
                }
                return
            }

            await MainActor.run {
                let state = CaptionGenerationState.shared
                guard runID == state.generationRunID else { return }
                state.stopElapsedTimer()
                state.segments = generated
                state.isTranscribing = false
                state.reportProgress(
                    runID: runID,
                    value: 1,
                    message: "Captions ready (\(generated.count) segments)",
                    force: true
                )
            }
        } catch SecurityScopedFileAccess.AccessError.denied {
            await MainActor.run {
                let state = CaptionGenerationState.shared
                if Task.isCancelled {
                    state.finishCancelled(runID: runID)
                    return
                }
                guard runID == state.generationRunID else { return }
                state.stopElapsedTimer()
                state.isTranscribing = false
                state.errorMessage = SecurityScopedFileAccess.accessDeniedMessage
                state.statusMessage = ""
                state.baseStatusMessage = ""
            }
        } catch {
            await MainActor.run {
                let state = CaptionGenerationState.shared
                if Task.isCancelled {
                    state.finishCancelled(runID: runID)
                    return
                }
                guard runID == state.generationRunID else { return }
                state.stopElapsedTimer()
                state.isTranscribing = false
                state.errorMessage = error.localizedDescription
                state.statusMessage = ""
                state.baseStatusMessage = ""
            }
        }
    }
}
