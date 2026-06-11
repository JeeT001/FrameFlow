//
//  FrameFlowTests.swift
//  FrameFlowTests
//

import Testing
@testable import FrameFlow

struct EditTimelineSegmentTests {
    private let duration: Double = 20
    private let minSpan = EditTimelineModel.minimumSpanSeconds

    @Test func razorSplitProducesTouchingSegmentsWithFullExport() {
        var timeline = EditTimelineModel(
            sourceDurationSeconds: duration,
            trimStartSeconds: 0,
            trimEndSeconds: duration
        )
        timeline.addSplitPoint(at: 10)

        let segments = timeline.videoClipSegments()
        #expect(segments.count == 2)
        #expect(abs(segments[0].effectiveEnd - 10) < 0.01)
        #expect(abs(segments[1].effectiveStart - 10) < 0.01)
        #expect(!segments[0].hasGapAfter)
        #expect(!segments[1].hasGapBefore)
        #expect(abs(timeline.exportDurationSeconds - duration) < 0.01)
    }

    @Test func trimSegmentOutCreatesGapAndShortensExport() {
        var timeline = EditTimelineModel(
            sourceDurationSeconds: duration,
            trimStartSeconds: 0,
            trimEndSeconds: duration
        )
        timeline.addSplitPoint(at: 10)
        let segmentA = timeline.videoClipSegments()[0]

        timeline.trimSegmentOut(segment: segmentA, newEffectiveEnd: 8)

        let updatedA = timeline.videoClipSegments()[0]
        #expect(abs(updatedA.effectiveEnd - 8) < 0.01)
        #expect(updatedA.hasGapAfter)
        #expect(timeline.removedRanges.contains { abs($0.startSeconds - 8) < 0.01 && abs($0.endSeconds - 10) < 0.01 })
        #expect(timeline.exportDurationSeconds < duration - 1.9)
    }

    @Test func extendSegmentOutRestoresGapContent() {
        var timeline = EditTimelineModel(
            sourceDurationSeconds: duration,
            trimStartSeconds: 0,
            trimEndSeconds: duration
        )
        timeline.addSplitPoint(at: 10)
        var segmentA = timeline.videoClipSegments()[0]
        timeline.trimSegmentOut(segment: segmentA, newEffectiveEnd: 8)
        segmentA = timeline.videoClipSegments()[0]

        timeline.extendSegmentOut(segment: segmentA, newEffectiveEnd: 9.5)

        let restored = timeline.videoClipSegments()[0]
        #expect(abs(restored.effectiveEnd - 9.5) < 0.01)
        #expect(timeline.exportDurationSeconds > duration - 1.6)
    }

    @Test func rippleCloseGapJoinsSegmentsAndRestoresExport() {
        var timeline = EditTimelineModel(
            sourceDurationSeconds: duration,
            trimStartSeconds: 0,
            trimEndSeconds: duration
        )
        timeline.addSplitPoint(at: 10)
        let segments = timeline.videoClipSegments()
        let segmentA = segments[0]
        let segmentB = segments[1]

        timeline.trimSegmentOut(segment: segmentA, newEffectiveEnd: 8)
        let exportAfterTrim = timeline.exportDurationSeconds

        let trimmedA = timeline.videoClipSegments()[0]
        let trimmedB = timeline.videoClipSegments()[1]
        timeline.rippleCloseGap(leftSegment: trimmedA, rightSegment: trimmedB, joinAt: 8)

        let joined = timeline.videoClipSegments()
        #expect(joined.count == 2)
        #expect(abs(joined[0].effectiveEnd - 8) < 0.01)
        #expect(abs(joined[1].effectiveStart - 8) < 0.01)
        #expect(!joined[0].hasGapAfter)
        #expect(!joined[1].hasGapBefore)
        #expect(timeline.exportDurationSeconds > exportAfterTrim)
        #expect(abs(timeline.exportDurationSeconds - duration) < 0.05)
    }

    @Test func moveSplitPointWithoutGapDoesNotChangeExportDuration() {
        var timeline = EditTimelineModel(
            sourceDurationSeconds: duration,
            trimStartSeconds: 0,
            trimEndSeconds: duration
        )
        timeline.addSplitPoint(at: 10)
        let before = timeline.exportDurationSeconds
        #expect(timeline.canMoveSplitBoundary(at: 0))

        timeline.moveSplitPoint(at: 0, to: 12)

        #expect(abs(timeline.splitPoints[0] - 12) < 0.01)
        #expect(abs(timeline.exportDurationSeconds - before) < 0.01)
    }

    @Test func minimumSpanEnforcedOnSegmentTrim() {
        var timeline = EditTimelineModel(
            sourceDurationSeconds: duration,
            trimStartSeconds: 0,
            trimEndSeconds: duration
        )
        timeline.addSplitPoint(at: 10)
        let segmentA = timeline.videoClipSegments()[0]
        let beforeEnd = segmentA.effectiveEnd

        timeline.trimSegmentOut(segment: segmentA, newEffectiveEnd: beforeEnd - 0.1)

        let updated = timeline.videoClipSegments()[0]
        #expect(updated.effectiveEnd >= updated.effectiveStart + minSpan - 0.01)
    }
}
