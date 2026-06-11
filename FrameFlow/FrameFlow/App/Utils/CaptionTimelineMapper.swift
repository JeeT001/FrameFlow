//
//  CaptionTimelineMapper.swift
//  FrameFlow
//

import Foundation

enum CaptionTimelineMapper {
    /// Map source playback time → export timeline time (nil if inside a removed gap).
    static func exportTime(fromSourceTime sourceTime: Double, editTimeline: EditTimelineModel) -> Double? {
        var accumulated = 0.0
        for range in editTimeline.keptSourceRanges {
            if sourceTime >= range.start, sourceTime < range.end {
                return accumulated + (sourceTime - range.start)
            }
            accumulated += range.duration
        }

        if let last = editTimeline.keptSourceRanges.last, abs(sourceTime - last.end) < 0.01 {
            return accumulated
        }
        return nil
    }

    /// Map export timeline time → source time for AVPlayer seek.
    static func sourceTime(fromExportTime exportTime: Double, editTimeline: EditTimelineModel) -> Double {
        var remaining = max(0, exportTime)
        for range in editTimeline.keptSourceRanges {
            let length = range.duration
            if remaining <= length || range == editTimeline.keptSourceRanges.last {
                return range.start + min(remaining, length)
            }
            remaining -= length
        }
        return editTimeline.keptSourceRanges.last?.end ?? editTimeline.trimEndSeconds
    }

    /// Segments with times relative to export timeline (t=0 at export start). For SRT + preview overlay.
    static func segmentsForExportTimeline(
        from segments: [CaptionSegment],
        editTimeline: EditTimelineModel
    ) -> [CaptionSegment] {
        var result: [CaptionSegment] = []

        for segment in segments {
            for kept in editTimeline.keptSourceRanges {
                guard segment.endTime > kept.start, segment.startTime < kept.end else { continue }

                let clippedStart = max(segment.startTime, kept.start)
                let clippedEnd = min(segment.endTime, kept.end)
                guard clippedEnd - clippedStart >= 0.01 else { continue }

                guard let exportStart = exportTime(fromSourceTime: clippedStart, editTimeline: editTimeline),
                      let exportEnd = exportTime(fromSourceTime: clippedEnd, editTimeline: editTimeline) else {
                    continue
                }

                var mapped = segment
                mapped.startTime = exportStart
                mapped.endTime = exportEnd
                guard !mapped.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                result.append(mapped)
            }
        }

        return result.sorted { $0.startTime < $1.startTime }
    }

    /// Absolute source times clipped to kept ranges — for burn-in on full source before stitch encode.
    static func segmentsForSourceBurnIn(
        from segments: [CaptionSegment],
        editTimeline: EditTimelineModel
    ) -> [CaptionSegment] {
        if editTimeline.isFullSourceExport {
            return segments
        }

        var result: [CaptionSegment] = []
        for segment in segments {
            for kept in editTimeline.keptSourceRanges {
                guard segment.endTime > kept.start, segment.startTime < kept.end else { continue }

                var clipped = segment
                clipped.startTime = max(segment.startTime, kept.start)
                clipped.endTime = min(segment.endTime, kept.end)
                guard clipped.endTime - clipped.startTime >= 0.01 else { continue }
                guard !clipped.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                result.append(clipped)
            }
        }
        return result.sorted { $0.startTime < $1.startTime }
    }

    /// Snap source time to nearest point inside a kept range (for scrub/seek).
    static func snapToKeptSourceTime(_ sourceTime: Double, editTimeline: EditTimelineModel) -> Double {
        if editTimeline.isFullSourceExport {
            return max(0, min(sourceTime, editTimeline.sourceDurationSeconds))
        }

        for range in editTimeline.keptSourceRanges {
            if sourceTime >= range.start, sourceTime <= range.end {
                return sourceTime
            }
        }

        var best = editTimeline.keptSourceRanges.first?.start ?? 0
        var bestDist = Double.greatestFiniteMagnitude
        for range in editTimeline.keptSourceRanges {
            for candidate in [range.start, range.end] {
                let dist = abs(sourceTime - candidate)
                if dist < bestDist {
                    bestDist = dist
                    best = candidate
                }
            }
        }
        return best
    }
}
