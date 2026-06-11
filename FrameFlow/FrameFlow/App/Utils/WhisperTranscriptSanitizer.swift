//
//  WhisperTranscriptSanitizer.swift
//  FrameFlow
//

import Foundation

enum WhisperTranscriptSanitizer {
    /// WhisperKit control tokens, e.g. `<|startoftranscript|>`, `<|endoftext|>`.
    private static let specialTokenPattern = /<\|[^|]+\|>/

    private static let knownNonSpeechPhrases: Set<String> = [
        "[blank_audio]",
        "[blank audio]",
        "(silence)",
        "[silence]",
        "[music]",
    ]

    /// Returns caption-ready speech text, or `nil` when the raw value is empty / non-speech.
    static func speechText(from raw: String) -> String? {
        var text = raw.replacing(specialTokenPattern, with: " ")
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        guard !knownNonSpeechPhrases.contains(text.lowercased()) else { return nil }
        guard text.contains(where: \.isLetter) else { return nil }
        return text
    }

    static func sanitizedSegments(from segments: [CaptionSegment]) -> [CaptionSegment] {
        segments.compactMap { segment in
            guard let text = speechText(from: segment.text) else { return nil }
            guard segment.endTime > segment.startTime + 0.001 else { return nil }
            var cleaned = segment
            cleaned.text = text
            return cleaned
        }
    }
}
