//
//  CaptionEngine.swift
//  FrameFlow
//

import Foundation

enum CaptionEngineError: LocalizedError {
    case sidecarWriteFailed(String)
    case recordingNotFound

    var errorDescription: String? {
        switch self {
        case .sidecarWriteFailed(let detail):
            return "Could not save captions: \(detail)"
        case .recordingNotFound:
            return "Recording file not found."
        }
    }
}

final class CaptionEngine: @unchecked Sendable {
    static let shared = CaptionEngine()

    private let transcription = TranscriptionService.shared
    private let renderer = CaptionRenderer.shared
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private init() {}

    func generateCaptions(
        for recordingURL: URL,
        recordingID: UUID,
        style: CaptionStyleConfig? = nil,
        progress: (@Sendable (Double, String) -> Void)? = nil
    ) async throws -> [CaptionSegment] {
        guard fileManager.fileExists(atPath: recordingURL.path) else {
            throw CaptionEngineError.recordingNotFound
        }

        let resolvedStyle = style ?? CaptionStyleConfig.fromSettings()

        progress?(0.1, "Extracting audio…")
        let audioURL = try await transcription.extractAudio(from: recordingURL)
        defer { try? fileManager.removeItem(at: audioURL) }

        let segments = try await transcription.transcribe(audioURL: audioURL, progress: progress)

        progress?(0.92, "Saving caption sidecar…")
        try saveCaptions(segments, for: recordingURL, recordingID: recordingID, style: resolvedStyle)

        let srtURL = srtURL(for: recordingURL)
        try renderer.writeSRT(segments: segments, to: srtURL)

        progress?(0.94, "Rendering captions into video…")
        let burnedURL = burnedInURL(for: recordingURL)
        try await renderer.burnInCaptions(
            videoURL: recordingURL,
            segments: segments,
            style: resolvedStyle,
            outputURL: burnedURL
        )

        progress?(1.0, "Captions ready.")
        return segments
    }

    func loadCaptions(for recordingURL: URL, recordingID: UUID) throws -> [CaptionSegment] {
        let raw = try loadSidecar(for: recordingURL, recordingID: recordingID)?.segments ?? []
        return WhisperTranscriptSanitizer.sanitizedSegments(from: raw)
    }

    func loadStyle(for recordingURL: URL, recordingID: UUID) -> CaptionStyleConfig {
        guard let sidecar = try? loadSidecar(for: recordingURL, recordingID: recordingID),
              let presetRaw = sidecar.stylePreset,
              let preset = CaptionStylePreset(rawValue: presetRaw) else {
            return CaptionStyleConfig.fromSettings()
        }

        let position = sidecar.styleVerticalPosition
            .flatMap(CaptionVerticalPosition.init(rawValue:)) ?? .bottom
        var style = CaptionStyleConfig.config(for: preset, position: position)
        style.customVerticalOffsetNormalized = sidecar.customVerticalOffsetNormalized
        return style
    }

    func saveCaptions(
        _ segments: [CaptionSegment],
        for recordingURL: URL,
        recordingID: UUID,
        style: CaptionStyleConfig
    ) throws {
        let cleaned = WhisperTranscriptSanitizer.sanitizedSegments(from: segments)
        let sidecar = CaptionSidecar(
            recordingID: recordingID,
            segments: cleaned,
            createdAt: Date(),
            stylePreset: style.preset.rawValue,
            styleVerticalPosition: style.verticalPosition.rawValue,
            customVerticalOffsetNormalized: style.customVerticalOffsetNormalized
        )

        let adjacent = sidecarURLAdjacent(to: recordingURL)
        try writeSidecar(sidecar, to: adjacent)

        let fallback = appSupportSidecarURL(recordingID: recordingID)
        try writeSidecar(sidecar, to: fallback)
    }

    func sidecarURLAdjacent(to recordingURL: URL) -> URL {
        recordingURL.deletingPathExtension().appendingPathExtension("captions.json")
    }

    func srtURL(for recordingURL: URL) -> URL {
        recordingURL.deletingPathExtension().appendingPathExtension("srt")
    }

    func burnedInURL(for recordingURL: URL) -> URL {
        let base = recordingURL.deletingPathExtension().lastPathComponent
        return recordingURL.deletingLastPathComponent()
            .appendingPathComponent("\(base)_captioned.mp4")
    }

    private func appSupportSidecarURL(recordingID: UUID) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FrameFlow/Captions", isDirectory: true)
        return base.appendingPathComponent("\(recordingID.uuidString).json")
    }

    private func loadSidecar(from url: URL) throws -> CaptionSidecar {
        let data = try Data(contentsOf: url)
        return try decoder.decode(CaptionSidecar.self, from: data)
    }

    private func loadSidecar(for recordingURL: URL, recordingID: UUID) throws -> CaptionSidecar? {
        let primary = sidecarURLAdjacent(to: recordingURL)
        if fileManager.fileExists(atPath: primary.path),
           let sidecar = try? loadSidecar(from: primary) {
            return sidecar
        }

        let fallback = appSupportSidecarURL(recordingID: recordingID)
        if fileManager.fileExists(atPath: fallback.path),
           let sidecar = try? loadSidecar(from: fallback) {
            return sidecar
        }

        return nil
    }

    private func writeSidecar(_ sidecar: CaptionSidecar, to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        do {
            let data = try encoder.encode(sidecar)
            try data.write(to: url, options: .atomic)
        } catch {
            throw CaptionEngineError.sidecarWriteFailed(error.localizedDescription)
        }
    }
}
