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

private final class TranscriptionProgressReporter: @unchecked Sendable {
    private var lastValue: Double = 0

    func report(_ value: Double, _ message: String, to progress: (@Sendable (Double, String) -> Void)?) {
        let clamped = max(lastValue, min(value, 1.0))
        lastValue = clamped
        progress?(clamped, message)
    }
}

final class TranscriptionService: @unchecked Sendable {
    static let shared = TranscriptionService()

    /// English-only base model — faster than multilingual default and skips remote config lookup.
    private static let preferredModel = "openai_whisper-base.en"

    private var whisperKit: WhisperKit?
    private var modelPrepareTask: Task<Void, Never>?
    private let modelLock = NSLock()

    private init() {}

    /// Loads WhisperKit in the background so the first post-record transcription is not blocked on download/specialization.
    func prepareModelInBackground() {
        modelLock.lock()
        if whisperKit != nil {
            modelLock.unlock()
            return
        }
        if modelPrepareTask != nil {
            modelLock.unlock()
            return
        }
        modelPrepareTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.loadWhisperKit(reporter: TranscriptionProgressReporter(), progress: nil)
            } catch {
                // Best-effort warm-up; generation will retry on demand.
            }
            await MainActor.run {
                self.modelLock.lock()
                self.modelPrepareTask = nil
                self.modelLock.unlock()
            }
        }
        modelLock.unlock()
    }

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
        let reporter = TranscriptionProgressReporter()
        reporter.report(0.05, "Loading speech model (first use may take 1–3 min)…", to: progress)

        let pipe = try await loadWhisperKit(reporter: reporter, progress: progress)
        reporter.report(0.22, "Transcribing speech…", to: progress)

        // Whisper processes long audio in 30s windows. Default `noSpeechThreshold` (0.6) skips a full
        // window when the model thinks it is silent — screen recordings often lose the opening minute.
        // We disable window skipping; `WhisperTranscriptSanitizer` drops blank / non-speech segments.
        let options = DecodingOptions(
            task: .transcribe,
            wordTimestamps: true,
            noSpeechThreshold: nil
        )
        var decodeProgress: Double = 0.22

        let results: [TranscriptionResult]
        do {
            results = try await pipe.transcribe(audioPath: audioURL.path, decodeOptions: options) { transcriptionProgress in
                let rtf = max(transcriptionProgress.timings.realTimeFactor, 0.05)
                decodeProgress = min(0.88, 0.22 + (0.66 * min(1.0, 1.0 / rtf * 0.15)))
                reporter.report(decodeProgress, "Transcribing speech…", to: progress)
                return true
            }
        } catch {
            throw TranscriptionServiceError.transcriptionFailed(error.localizedDescription)
        }

        reporter.report(0.9, "Building caption segments…", to: progress)

        let segments = WhisperTranscriptSanitizer.sanitizedSegments(
            from: mapResultsToSegments(results)
        )
        guard !segments.isEmpty else {
            throw TranscriptionServiceError.emptyTranscript
        }

        reporter.report(0.95, "Transcription complete.", to: progress)

        return segments
    }

    private func loadWhisperKit(
        reporter: TranscriptionProgressReporter,
        progress: (@Sendable (Double, String) -> Void)?
    ) async throws -> WhisperKit {
        modelLock.lock()
        if let existing = whisperKit {
            modelLock.unlock()
            return existing
        }
        modelLock.unlock()

        reporter.report(0.08, "Downloading speech model (first use only)…", to: progress)

        let config = WhisperKitConfig(
            model: Self.preferredModel,
            verbose: false,
            logLevel: .error,
            prewarm: false,
            load: true,
            download: true
        )

        let pipe = try await WhisperKit(config)

        pipe.modelStateCallback = { _, newState in
            switch newState {
            case .downloading:
                reporter.report(0.1, "Downloading speech model (first use only)…", to: progress)
            case .loading, .prewarming:
                reporter.report(0.14, "Preparing speech model for your Mac…", to: progress)
            case .loaded:
                reporter.report(0.2, "Speech model ready.", to: progress)
            default:
                break
            }
        }

        pipe.transcriptionStateCallback = { state in
            switch state {
            case .convertingAudio:
                reporter.report(0.18, "Converting audio for Whisper…", to: progress)
            case .transcribing, .finished:
                break
            }
        }

        modelLock.lock()
        whisperKit = pipe
        modelLock.unlock()

        return pipe
    }

    private func mapResultsToSegments(_ results: [TranscriptionResult]) -> [CaptionSegment] {
        var output: [CaptionSegment] = []

        for result in results {
            for segment in result.segments {
                let speechWords = segment.words?.compactMap { word -> WordTiming? in
                    guard WhisperTranscriptSanitizer.speechText(from: word.word) != nil else { return nil }
                    return word
                }

                if let speechWords, speechWords.count >= 2 {
                    output.append(contentsOf: mergeWordsIntoPhrases(speechWords))
                    continue
                }

                if let words = segment.words, words.count == 1,
                   let single = WhisperTranscriptSanitizer.speechText(from: words[0].word) {
                    output.append(
                        CaptionSegment(
                            text: single,
                            startTime: Double(words[0].start),
                            endTime: Double(words[0].end)
                        )
                    )
                    continue
                }

                guard let trimmed = WhisperTranscriptSanitizer.speechText(from: segment.text) else { continue }

                output.append(
                    CaptionSegment(
                        text: trimmed,
                        startTime: Double(segment.start),
                        endTime: Double(segment.end)
                    )
                )
            }
        }

        return output
    }

    /// Groups word timings into short phrases (~2–6 words) for readable on-screen captions.
    private func mergeWordsIntoPhrases(_ words: [WordTiming], minWords: Int = 2, maxWords: Int = 6) -> [CaptionSegment] {
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
            let text = chunk
                .compactMap { WhisperTranscriptSanitizer.speechText(from: $0.word) }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
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
