//
//  CaptionExportTimeline.swift
//  FrameFlow
//

import Foundation

/// Aligns caption segment times between editor preview and export burn-in.
enum CaptionExportTimeline {
    private static let stretchThresholdSeconds = 0.15

    /// Maps video-content playback time to audio-file timeline for Whisper segment lookup.
    static func audioTimelineTime(
        videoContentTime: Double,
        leadingGap: Double,
        audioDuration: Double,
        videoDuration: Double
    ) -> Double {
        let gap = max(0, leadingGap)
        let audioContent = max(0.01, audioDuration - gap)
        let videoContent = max(0.01, videoDuration - gap)
        let clampedVideo = min(max(0, videoContentTime), videoContent)
        let progress = clampedVideo / videoContent
        return gap + progress * audioContent
    }

    /// Maps file-timeline segments to export-timeline (t=0 at first visible video frame).
    static func segmentsForBurnIn(
        from segments: [CaptionSegment],
        leadingGap: Double,
        audioDuration: Double,
        videoDuration: Double
    ) -> [CaptionSegment] {
        let cleaned = WhisperTranscriptSanitizer.sanitizedSegments(from: segments)
        let gap = max(0, leadingGap)
        let audioContent = max(0.01, audioDuration - gap)
        let videoContent = max(0.01, videoDuration - gap)
        let needsStretch = abs(audioContent - videoContent) > stretchThresholdSeconds

        guard needsStretch || gap > 0.001 else { return cleaned }

        return cleaned.compactMap { segment in
            guard segment.endTime > gap + 0.01 else { return nil }
            var adjusted = segment
            if needsStretch {
                let audioStart = segment.startTime - gap
                let audioEnd = segment.endTime - gap
                adjusted.startTime = max(0, audioStart / audioContent * videoContent)
                adjusted.endTime = max(adjusted.startTime + 0.05, audioEnd / audioContent * videoContent)
            } else {
                adjusted.startTime = max(0, segment.startTime - gap)
                adjusted.endTime = max(adjusted.startTime + 0.05, segment.endTime - gap)
            }
            adjusted.endTime = min(adjusted.endTime, videoContent)
            guard adjusted.startTime < adjusted.endTime - 0.01 else { return nil }
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
