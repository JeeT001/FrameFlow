//
//  CaptionExportTimeline.swift
//  FrameFlow
//

import Foundation

/// Aligns caption segment times between editor preview and export burn-in.
enum CaptionExportTimeline {
    /// Maps file-timeline segments to export-timeline (t=0 at first visible video frame).
    static func segmentsForBurnIn(
        from segments: [CaptionSegment],
        leadingGap: Double
    ) -> [CaptionSegment] {
        let cleaned = WhisperTranscriptSanitizer.sanitizedSegments(from: segments)
        guard leadingGap > 0.001 else { return cleaned }

        return cleaned.compactMap { segment in
            guard segment.endTime > leadingGap + 0.01 else { return nil }
            var adjusted = segment
            adjusted.startTime = max(0, segment.startTime - leadingGap)
            adjusted.endTime = max(adjusted.startTime + 0.05, segment.endTime - leadingGap)
            return adjusted
        }
    }

    /// Resolves the same leading gap used by editor preview and export trim.
    static func resolvedLeadingGap(
        editorLeadingGap: Double,
        metadataLead: Double,
        probedFromAsset: Double
    ) -> Double {
        if editorLeadingGap > 0.001 {
            return editorLeadingGap
        }
        if probedFromAsset > 0.001 {
            if metadataLead > probedFromAsset + 1.0 {
                return probedFromAsset
            }
            return max(metadataLead, probedFromAsset)
        }
        if metadataLead > 5.0 {
            return 0
        }
        return max(0, metadataLead)
    }
}
