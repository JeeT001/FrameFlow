//
//  FrameFlowTests.swift
//  FrameFlowTests
//

import Testing
@testable import FrameFlow

struct GlobalTrimTests {
    private let duration: Double = 60

    @Test func trimStartShiftsKeptRangeStart() {
        var timeline = EditTimelineModel(
            sourceDurationSeconds: duration,
            trimStartSeconds: 0,
            trimEndSeconds: duration
        )
        timeline.updateTrimStart(5)
        let kept = timeline.keptSourceRanges
        #expect(kept.count == 1)
        #expect(abs(kept[0].start - 5) < 0.01)
    }

    @Test func trimEndShortensKeptRangeEnd() {
        var timeline = EditTimelineModel(
            sourceDurationSeconds: duration,
            trimStartSeconds: 0,
            trimEndSeconds: duration
        )
        timeline.updateTrimEnd(55)
        #expect(abs(timeline.keptSourceRanges[0].end - 55) < 0.01)
    }

    @Test func exportDurationMatchesTrimSpan() {
        let timeline = EditTimelineModel(
            sourceDurationSeconds: duration,
            trimStartSeconds: 5,
            trimEndSeconds: 35
        )
        #expect(abs(timeline.exportDurationSeconds - 30) < 0.01)
    }

    @Test func captionSegmentBeforeTrimExcludedFromExportTimeline() {
        let timeline = EditTimelineModel(
            sourceDurationSeconds: duration,
            trimStartSeconds: 5,
            trimEndSeconds: duration
        )
        let segments = [
            CaptionSegment(text: "before trim", startTime: 2, endTime: 4)
        ]
        let mapped = CaptionTimelineMapper.segmentsForExportTimeline(
            from: segments,
            editTimeline: timeline
        )
        #expect(mapped.isEmpty)
    }

    @Test func captionSegmentSpanningTrimEdgeIsClipped() {
        let timeline = EditTimelineModel(
            sourceDurationSeconds: duration,
            trimStartSeconds: 5,
            trimEndSeconds: duration
        )
        let segments = [
            CaptionSegment(text: "spanning in", startTime: 3, endTime: 8)
        ]
        let mapped = CaptionTimelineMapper.segmentsForExportTimeline(
            from: segments,
            editTimeline: timeline
        )
        #expect(mapped.count == 1)
        #expect(abs(mapped[0].startTime - 0) < 0.02)
        #expect(abs(mapped[0].endTime - 3) < 0.02)
    }
}

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

struct FreeFormPlacementTests {
    private let canvasSize = CGSize(width: 1920, height: 1080)
    private let windowAspect: CGFloat = 9.0 / 16.0

    @Test func defaultCenterCountMatchesWindowCount() {
        #expect(WindowPlacementMath.freeFormDefaultCenters(count: 1).count == 1)
        #expect(WindowPlacementMath.freeFormDefaultCenters(count: 2).count == 2)
        #expect(WindowPlacementMath.freeFormDefaultCenters(count: 3).count == 3)
        #expect(WindowPlacementMath.freeFormDefaultCenters(count: 4).count == 4)
    }

    @Test func fourWindowCentersMapToDistinctQuadrants() {
        let centers = WindowPlacementMath.freeFormDefaultCenters(count: 4)
        #expect(centers[0].x < 0.5 && centers[0].y > 0.5)
        #expect(centers[1].x > 0.5 && centers[1].y > 0.5)
        #expect(centers[2].x < 0.5 && centers[2].y < 0.5)
        #expect(centers[3].x > 0.5 && centers[3].y < 0.5)
    }

    @Test func maxFractionDecreasesAsWindowCountIncreases() {
        let one = WindowPlacementMath.freeFormMaxFraction(windowCount: 1)
        let two = WindowPlacementMath.freeFormMaxFraction(windowCount: 2)
        let three = WindowPlacementMath.freeFormMaxFraction(windowCount: 3)
        let four = WindowPlacementMath.freeFormMaxFraction(windowCount: 4)
        #expect(one > two)
        #expect(two > three)
        #expect(three > four)
    }

    @Test func seededRectsDoNotOverlapBeyondTolerance() {
        for count in 1...4 {
            let rects = WindowPlacementMath.freeFormDefaultNormalizedRects(
                count: count,
                windowAspect: windowAspect,
                canvasSize: canvasSize
            )
            for i in 0..<rects.count {
                for j in (i + 1)..<rects.count {
                    let overlap = rects[i].intersection(rects[j])
                    #expect(overlap.width * overlap.height < 0.0005)
                }
            }
        }
    }
}
