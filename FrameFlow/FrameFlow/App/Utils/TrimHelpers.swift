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
        formatExportDurationDisplay(seconds, sourceDuration: nil)
    }

    /// Shows fractional seconds when export length is close to source so small cuts remain visible.
    static func formatExportDurationDisplay(_ exportSeconds: Double, sourceDuration: Double?) -> String {
        let export = max(0, exportSeconds)
        let minutes = Int(export) / 60
        let secs = export.truncatingRemainder(dividingBy: 60)

        let showFraction: Bool = {
            guard let sourceDuration, sourceDuration > 0 else { return export < 60 }
            let delta = abs(sourceDuration - export)
            return delta > 0.05 && delta < 10
        }()

        if showFraction {
            if minutes > 0 {
                return String(format: "%d:%05.2f", minutes, secs)
            }
            return String(format: "0:%05.2f", secs)
        }

        let total = max(0, Int(export.rounded()))
        let roundedMinutes = total / 60
        let roundedSecs = total % 60
        return String(format: "%d:%02d", roundedMinutes, roundedSecs)
    }
}
