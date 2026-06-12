//
//  CaptionSyncOffset.swift
//  FrameFlow
//

import Foundation

/// Aligns Whisper (audio-timeline) caption timestamps with video playback time.
///
/// Recording starts audio before the first video frame is written, so Whisper segment
/// times are ~1s ahead of what AVPlayer reports for the same on-screen moment.
enum CaptionSyncOffset {
    /// Player time → audio-timeline time for segment lookup.
    static func audioTimelineTime(fromPlayerTime playerTime: Double, audioLeadSeconds: Double) -> Double {
        playerTime + max(0, audioLeadSeconds)
    }

    /// Audio-timeline segment time → video-timeline time for burn-in / export layers.
    static func videoTimelineTime(fromAudioTime audioTime: Double, audioLeadSeconds: Double) -> Double {
        max(0, audioTime - max(0, audioLeadSeconds))
    }

    static func segmentsAlignedToVideoTimeline(
        _ segments: [CaptionSegment],
        audioLeadSeconds: Double
    ) -> [CaptionSegment] {
        let lead = max(0, audioLeadSeconds)
        guard lead > 0.001 else { return segments }

        return segments.compactMap { segment in
            let start = videoTimelineTime(fromAudioTime: segment.startTime, audioLeadSeconds: lead)
            let end = videoTimelineTime(fromAudioTime: segment.endTime, audioLeadSeconds: lead)
            guard end - start >= 0.01 else { return nil }
            var aligned = segment
            aligned.startTime = start
            aligned.endTime = end
            return aligned
        }
    }
}
