//
//  TranscriptionService.swift
//  FrameFlow
//

import AVFoundation
import Foundation
import WhisperKit

enum TranscriptionServiceError: LocalizedError {
    case noAudioTrack
    case extractionFailed(String)
    case transcriptionFailed(String)
    case emptyTranscript

    var errorDescription: String? {
        switch self {
        case .noAudioTrack:
            return "This recording has no audio track to transcribe."
        case .extractionFailed(let detail):
            return "Could not extract audio: \(detail)"
        case .transcriptionFailed(let detail):
            return "Transcription failed: \(detail)"
        case .emptyTranscript:
            return "No speech was detected in this recording."
        }
    }
}

final class TranscriptionService: @unchecked Sendable {
    static let shared = TranscriptionService()

    private var whisperKit: WhisperKit?

    private init() {}

    func videoHasAudioTrack(at videoURL: URL) async -> Bool {
        let asset = AVURLAsset(url: videoURL)
        let tracks = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
        return !tracks.isEmpty
    }

    func extractAudio(from videoURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            throw TranscriptionServiceError.noAudioTrack
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("frameflow_audio_\(UUID().uuidString).m4a")

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw TranscriptionServiceError.extractionFailed("Export session unavailable.")
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await exportSession.export()

        if let error = exportSession.error {
            throw TranscriptionServiceError.extractionFailed(error.localizedDescription)
        }
        guard exportSession.status == .completed else {
            throw TranscriptionServiceError.extractionFailed("Export ended with status \(exportSession.status.rawValue).")
        }

        return outputURL
    }

    func transcribe(
        audioURL: URL,
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) async throws -> [CaptionSegment] {
        progress?(0.05, "Loading WhisperKit (first run may download models)…")

        let pipe = try await loadWhisperKit(progress: progress)
        progress?(0.22, "Transcribing speech…")

        let options = DecodingOptions(task: .transcribe, wordTimestamps: true)
        var decodeProgress: Double = 0.22

        let results: [TranscriptionResult]
        do {
            results = try await pipe.transcribe(audioPath: audioURL.path, decodeOptions: options) { transcriptionProgress in
                let rtf = max(transcriptionProgress.timings.realTimeFactor, 0.05)
                decodeProgress = min(0.88, 0.22 + (0.66 * min(1.0, 1.0 / rtf * 0.15)))
                progress?(decodeProgress, "Transcribing…")
                return true
            }
        } catch {
            throw TranscriptionServiceError.transcriptionFailed(error.localizedDescription)
        }

        progress?(0.9, "Building caption segments…")

        let segments = mapResultsToSegments(results)
        guard !segments.isEmpty else {
            throw TranscriptionServiceError.emptyTranscript
        }

        progress?(0.95, "Transcription complete.")
        return segments
    }

    private func loadWhisperKit(progress: (@Sendable (Double, String) -> Void)?) async throws -> WhisperKit {
        if let existing = whisperKit { return existing }

        progress?(0.08, "Preparing on-device speech model…")

        let pipe = try await WhisperKit()
        whisperKit = pipe

        pipe.transcriptionStateCallback = { state in
            switch state {
            case .convertingAudio:
                progress?(0.18, "Converting audio for Whisper…")
            case .transcribing:
                progress?(0.25, "Transcribing…")
            case .finished:
                break
            }
        }

        return pipe
    }

    private func mapResultsToSegments(_ results: [TranscriptionResult]) -> [CaptionSegment] {
        var output: [CaptionSegment] = []

        for result in results {
            for segment in result.segments {
                let trimmed = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }

                if let words = segment.words, words.count >= 2 {
                    output.append(contentsOf: mergeWordsIntoPhrases(words))
                } else {
                    output.append(
                        CaptionSegment(
                            text: trimmed,
                            startTime: Double(segment.start),
                            endTime: Double(segment.end)
                        )
                    )
                }
            }
        }

        return output
    }

    /// Groups word timings into short phrases (~3–8 words) for readable on-screen captions.
    private func mergeWordsIntoPhrases(_ words: [WordTiming], minWords: Int = 3, maxWords: Int = 6) -> [CaptionSegment] {
        var phrases: [CaptionSegment] = []
        var index = 0

        while index < words.count {
            let remaining = words.count - index
            let chunkSize: Int
            if remaining <= maxWords {
                chunkSize = remaining
            } else if remaining <= maxWords + minWords {
                chunkSize = (remaining + 1) / 2
            } else {
                chunkSize = maxWords
            }

            let endIndex = index + chunkSize
            let chunk = Array(words[index..<endIndex])
            let text = chunk.map(\.word).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty, let first = chunk.first, let last = chunk.last {
                phrases.append(
                    CaptionSegment(
                        text: text,
                        startTime: Double(first.start),
                        endTime: Double(last.end)
                    )
                )
            }
            index = endIndex
        }

        return phrases
    }
}
