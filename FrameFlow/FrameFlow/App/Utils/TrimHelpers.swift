//
//  TrimHelpers.swift
//  FrameFlow
//

import Foundation

enum TrimHelpers {
    static let minimumSpanSeconds: Double = 0.5

    /// Clips segments to `[trimStart, trimEnd]`. When `relativeToTrimStart` is true, times are shifted so trim start is t=0.
    static func segmentsForExport(
        from segments: [CaptionSegment],
        trimStart: Double,
        trimEnd: Double,
        relativeToTrimStart: Bool = false
    ) -> [CaptionSegment] {
        guard trimEnd > trimStart else { return [] }

        var result: [CaptionSegment] = []
        for var segment in segments {
            guard segment.endTime > trimStart, segment.startTime < trimEnd else { continue }

            let clippedStart = max(segment.startTime, trimStart)
            let clippedEnd = min(segment.endTime, trimEnd)
            guard clippedEnd - clippedStart >= 0.01 else { continue }

            segment.startTime = clippedStart
            segment.endTime = clippedEnd

            if relativeToTrimStart {
                segment.startTime -= trimStart
                segment.endTime -= trimStart
            }

            guard !segment.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            result.append(segment)
        }
        return result
    }

    static func formatTimelineTime(_ seconds: Double) -> String {
        let clamped = max(0, seconds)
        let minutes = Int(clamped) / 60
        let secs = clamped.truncatingRemainder(dividingBy: 60)
        if minutes > 0 {
            return String(format: "%d:%04.1f", minutes, secs)
        }
        return String(format: "%.1fs", secs)
    }

    static func formatDurationClock(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
