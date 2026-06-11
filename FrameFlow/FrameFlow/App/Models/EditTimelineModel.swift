//
//  EditTimelineModel.swift
//  FrameFlow
//

import Foundation

struct RemovedRange: Codable, Equatable, Sendable {
    var startSeconds: Double
    var endSeconds: Double

    var duration: Double { max(0, endSeconds - startSeconds) }
}

struct KeptSourceRange: Codable, Equatable, Sendable {
    var start: Double
    var end: Double

    var duration: Double { max(0, end - start) }
}

struct EditTimelineModel: Equatable, Sendable {
    static let minimumSpanSeconds: Double = 0.5

    var sourceDurationSeconds: Double
    var trimStartSeconds: Double
    var trimEndSeconds: Double
    var removedRanges: [RemovedRange] = []
    /// Razor split markers on the source timeline (visual + selection aid).
    var splitPoints: [Double] = []
    /// Maps playback slot → index in `segmentSourceRanges` (default identity order).
    var segmentOrder: [Int] = []

    /// First removed range (legacy convenience).
    var removedRange: RemovedRange? { removedRanges.first }

    var hasRemovedRegions: Bool { !removedRanges.isEmpty }
    var hasMiddleDelete: Bool { hasRemovedRegions }

    var hasTrimApplied: Bool {
        trimStartSeconds > 0.001 || trimEndSeconds < sourceDurationSeconds - 0.001
    }

    var requiresStitchExport: Bool {
        hasRemovedRegions || hasTrimApplied || isSegmentOrderCustomized
    }

    var isFullSourceExport: Bool {
        !requiresStitchExport
    }

    var sortedRemovedRanges: [RemovedRange] {
        removedRanges.sorted { $0.startSeconds < $1.startSeconds }
    }

    /// Always derived from trim + removed state — never stale on struct copy.
    var keptSourceRanges: [KeptSourceRange] {
        var ranges = [KeptSourceRange(start: clampedTrimStart, end: clampedTrimEnd)]
        for removed in sortedRemovedRanges {
            var next: [KeptSourceRange] = []
            for range in ranges {
                next.append(contentsOf: Self.subtract(range, by: removed))
            }
            ranges = next
        }
        return ranges.filter { $0.duration > 0.001 }
    }

    var exportDurationSeconds: Double {
        keptSourceRanges.reduce(0) { $0 + $1.duration }
    }

    /// One reorderable span per razor segment (effective kept in/out per block).
    var segmentSourceRanges: [KeptSourceRange] {
        let segments = videoClipSegments()
        if segments.isEmpty {
            return keptSourceRanges
        }
        return segments.map { KeptSourceRange(start: $0.effectiveStart, end: $0.effectiveEnd) }
    }

    var isSegmentOrderCustomized: Bool {
        let ranges = segmentSourceRanges
        guard ranges.count > 1, segmentOrder.count == ranges.count else { return false }
        return segmentOrder != Array(0..<ranges.count)
    }

    /// Playback order for export / packed timeline UI.
    var orderedSourceRanges: [KeptSourceRange] {
        let ranges = segmentSourceRanges
        guard !ranges.isEmpty else { return keptSourceRanges }
        guard segmentOrder.count == ranges.count else { return ranges }
        return segmentOrder.compactMap { idx in
            idx < ranges.count ? ranges[idx] : nil
        }
    }

    mutating func normalizeSegmentOrder() {
        let count = segmentSourceRanges.count
        guard segmentOrder.count != count else { return }
        if count == 0 {
            segmentOrder = []
        } else {
            segmentOrder = Array(0..<count)
        }
    }

    mutating func moveSegment(from fromIndex: Int, to toIndex: Int) {
        normalizeSegmentOrder()
        guard fromIndex != toIndex,
              fromIndex >= 0, fromIndex < segmentOrder.count,
              toIndex >= 0, toIndex < segmentOrder.count else { return }
        let item = segmentOrder.remove(at: fromIndex)
        segmentOrder.insert(item, at: toIndex)
    }

    var totalRemovedSeconds: Double {
        sortedRemovedRanges.reduce(0) { $0 + $1.duration }
    }

    init(
        sourceDurationSeconds: Double = 1,
        trimStartSeconds: Double = 0,
        trimEndSeconds: Double = 1,
        removedRanges: [RemovedRange] = []
    ) {
        self.sourceDurationSeconds = max(sourceDurationSeconds, Self.minimumSpanSeconds)
        self.trimStartSeconds = trimStartSeconds
        self.trimEndSeconds = trimEndSeconds
        self.removedRanges = removedRanges
        clampTrimHandles()
        pruneInvalidRemovedRanges()
    }

    func preparedForExport() -> EditTimelineModel {
        var model = self
        model.clampTrimHandles()
        model.pruneInvalidRemovedRanges()
        return model
    }

    mutating func configureSourceDuration(_ duration: Double) {
        sourceDurationSeconds = max(duration, Self.minimumSpanSeconds)
        trimStartSeconds = 0
        trimEndSeconds = sourceDurationSeconds
        removedRanges = []
        splitPoints = []
        segmentOrder = []
        clampTrimHandles()
    }

    mutating func updateTrimStart(_ value: Double) {
        trimStartSeconds = value
        clampTrimHandles()
        pruneInvalidRemovedRanges()
    }

    mutating func updateTrimEnd(_ value: Double) {
        trimEndSeconds = value
        clampTrimHandles()
        pruneInvalidRemovedRanges()
    }

    mutating func addRemovedRange(start: Double, end: Double) {
        let lo = min(start, end)
        let hi = max(start, end)
        guard canApplyRemovedRange(start: lo, end: hi) else { return }
        appendRemovedSpan(start: lo, end: hi)
    }

    mutating func setRemovedRange(start: Double, end: Double) {
        removedRanges = []
        addRemovedRange(start: start, end: end)
    }

    mutating func clearRemovedRanges() {
        removedRanges = []
        normalizeSegmentOrder()
    }

    mutating func removeRemovedRange(at index: Int) {
        let sorted = sortedRemovedRanges
        guard sorted.indices.contains(index) else { return }
        let target = sorted[index]
        removedRanges.removeAll {
            abs($0.startSeconds - target.startSeconds) < 0.001
                && abs($0.endSeconds - target.endSeconds) < 0.001
        }
    }

    mutating func clearRemovedRange() {
        clearRemovedRanges()
    }

    mutating func addSplitPoint(at seconds: Double) {
        let clamped = min(max(seconds, clampedTrimStart), clampedTrimEnd)
        if !splitPoints.contains(where: { abs($0 - clamped) < 0.05 }) {
            splitPoints.append(clamped)
            splitPoints.sort()
            normalizeSegmentOrder()
        }
    }

    mutating func moveSplitPoint(at index: Int, to newSourceSeconds: Double) {
        guard splitPoints.indices.contains(index) else { return }
        let minSpan = Self.minimumSpanSeconds
        let prevBound = index == 0 ? clampedTrimStart : splitPoints[index - 1]
        let nextBound = index + 1 < splitPoints.count ? splitPoints[index + 1] : clampedTrimEnd
        let clamped = max(prevBound + minSpan, min(newSourceSeconds, nextBound - minSpan))
        splitPoints[index] = clamped
        splitPoints.sort()
    }

    func splitPointIndex(near sourceSeconds: Double, tolerance: Double = 0.1) -> Int? {
        splitPoints.firstIndex { abs($0 - sourceSeconds) < tolerance }
    }

    /// True when neighbors touch at this split with no export gap on the boundary.
    func canMoveSplitBoundary(at splitIndex: Int) -> Bool {
        guard splitPoints.indices.contains(splitIndex) else { return false }
        let splitTime = splitPoints[splitIndex]
        let segments = videoClipSegments()
        guard let left = segments.first(where: { $0.splitIndexAtEnd == splitIndex }),
              let right = segments.first(where: { $0.splitIndexAtStart == splitIndex }) else {
            return false
        }
        guard !left.hasGapAfter, !right.hasGapBefore else { return false }
        guard abs(left.effectiveEnd - right.effectiveStart) < 0.05 else { return false }
        return !removedRanges.contains {
            $0.startSeconds < splitTime + 0.05 && $0.endSeconds > splitTime - 0.05
        }
    }

    /// Visual segments for razor-cut UI; export gaps use `removedRanges`.
    func videoClipSegments() -> [VideoClipSegment] {
        var segments: [VideoClipSegment] = []
        let sortedSplits = splitPoints.sorted()
        let boundaries = [clampedTrimStart] + sortedSplits + [clampedTrimEnd]
        var nextID = 0

        for index in 0..<(boundaries.count - 1) {
            let boundaryStart = boundaries[index]
            let boundaryEnd = boundaries[index + 1]
            guard boundaryEnd - boundaryStart >= Self.minimumSpanSeconds - 0.001 else { continue }

            let splitAtStart = sortedSplits.firstIndex { abs($0 - boundaryStart) < 0.05 }
            let splitAtEnd = sortedSplits.firstIndex { abs($0 - boundaryEnd) < 0.05 }

            let keptInBoundary = keptSourceRanges.compactMap { kept -> KeptSourceRange? in
                let start = max(kept.start, boundaryStart)
                let end = min(kept.end, boundaryEnd)
                guard end - start > 0.001 else { return nil }
                return KeptSourceRange(start: start, end: end)
            }

            for kept in keptInBoundary {
                guard kept.duration >= Self.minimumSpanSeconds - 0.001 else { continue }
                let hasGapBefore = kept.start > boundaryStart + 0.001
                let hasGapAfter = kept.end < boundaryEnd - 0.001
                segments.append(
                    VideoClipSegment(
                        id: nextID,
                        sourceStart: boundaryStart,
                        sourceEnd: boundaryEnd,
                        splitIndexAtStart: splitAtStart,
                        splitIndexAtEnd: splitAtEnd,
                        effectiveStart: kept.start,
                        effectiveEnd: kept.end,
                        hasGapBefore: hasGapBefore,
                        hasGapAfter: hasGapAfter
                    )
                )
                nextID += 1
            }
        }
        return segments
    }

    // MARK: - Segment trim / ripple

    mutating func trimSegmentOut(segment: VideoClipSegment, newEffectiveEnd: Double) {
        let minSpan = Self.minimumSpanSeconds
        let clamped = max(
            segment.effectiveStart + minSpan,
            min(newEffectiveEnd, segment.sourceEnd)
        )
        let oldEnd = segment.effectiveEnd
        guard clamped < oldEnd - 0.001 else { return }
        appendRemovedSpan(start: clamped, end: oldEnd)
        finishSegmentMutation()
    }

    mutating func trimSegmentIn(segment: VideoClipSegment, newEffectiveStart: Double) {
        let minSpan = Self.minimumSpanSeconds
        let clamped = max(
            segment.sourceStart,
            min(newEffectiveStart, segment.effectiveEnd - minSpan)
        )
        let oldStart = segment.effectiveStart
        guard clamped > oldStart + 0.001 else { return }
        appendRemovedSpan(start: oldStart, end: clamped)
        finishSegmentMutation()
    }

    mutating func extendSegmentOut(segment: VideoClipSegment, newEffectiveEnd: Double) {
        let minSpan = Self.minimumSpanSeconds
        let clamped = max(
            segment.effectiveStart + minSpan,
            min(newEffectiveEnd, segment.sourceEnd)
        )
        let oldEnd = segment.effectiveEnd
        guard clamped > oldEnd + 0.001 else { return }
        shrinkRemovedSpan(towardEndFrom: oldEnd, to: clamped)
        finishSegmentMutation()
    }

    mutating func extendSegmentIn(segment: VideoClipSegment, newEffectiveStart: Double) {
        let minSpan = Self.minimumSpanSeconds
        let clamped = max(
            segment.sourceStart,
            min(newEffectiveStart, segment.effectiveEnd - minSpan)
        )
        let oldStart = segment.effectiveStart
        guard clamped < oldStart - 0.001 else { return }
        shrinkRemovedSpan(towardStartFrom: oldStart, to: clamped)
        finishSegmentMutation()
    }

    mutating func rippleCloseGap(
        leftSegment: VideoClipSegment,
        rightSegment: VideoClipSegment,
        joinAt: Double
    ) {
        let minSpan = Self.minimumSpanSeconds
        let gapStart = leftSegment.effectiveEnd
        let gapEnd = rightSegment.effectiveStart
        guard gapEnd - gapStart > 0.001 else { return }

        let clampedJoin = max(
            gapStart,
            min(joinAt, gapEnd - minSpan)
        )
        shrinkRemovedSpan(towardStartFrom: gapEnd, to: clampedJoin)

        if let splitIndex = rightSegment.splitIndexAtStart {
            moveSplitPoint(at: splitIndex, to: clampedJoin)
        } else if let splitIndex = leftSegment.splitIndexAtEnd {
            moveSplitPoint(at: splitIndex, to: clampedJoin)
        }
        finishSegmentMutation()
    }

    func canApplyRemovedRange(start: Double, end: Double) -> Bool {
        let lo = min(start, end)
        let hi = max(start, end)
        let minSpan = Self.minimumSpanSeconds
        let trimStart = clampedTrimStart
        let trimEnd = clampedTrimEnd
        guard hi - lo >= minSpan else { return false }
        guard lo >= trimStart + minSpan else { return false }
        guard hi <= trimEnd - minSpan else { return false }

        for existing in sortedRemovedRanges {
            if lo < existing.endSeconds && hi > existing.startSeconds {
                return false
            }
        }
        return true
    }

    func canApplySegmentTrim(start: Double, end: Double) -> Bool {
        let lo = min(start, end)
        let hi = max(start, end)
        guard hi - lo >= 0.001 else { return false }
        guard lo >= clampedTrimStart - 0.001 else { return false }
        guard hi <= clampedTrimEnd + 0.001 else { return false }
        let hypothetical = self
        var model = hypothetical
        model.appendRemovedSpan(start: lo, end: hi)
        return model.keptSourceRanges.contains { $0.duration >= Self.minimumSpanSeconds - 0.001 }
    }

    // MARK: - Private helpers

    private var clampedTrimStart: Double {
        let minSpan = Self.minimumSpanSeconds
        return max(0, min(trimStartSeconds, sourceDurationSeconds - minSpan))
    }

    private var clampedTrimEnd: Double {
        let minSpan = Self.minimumSpanSeconds
        let start = clampedTrimStart
        return min(sourceDurationSeconds, max(trimEndSeconds, start + minSpan))
    }

    mutating func clampTrimHandles() {
        trimStartSeconds = clampedTrimStart
        trimEndSeconds = clampedTrimEnd
    }

    mutating func pruneInvalidRemovedRanges() {
        removedRanges = removedRanges.filter {
            $0.endSeconds - $0.startSeconds > 0.001
                && $0.startSeconds >= clampedTrimStart - 0.001
                && $0.endSeconds <= clampedTrimEnd + 0.001
        }
        removedRanges = Self.mergeOverlapping(removedRanges)
        splitPoints = splitPoints.filter { $0 >= clampedTrimStart && $0 <= clampedTrimEnd }
        pruneDegenerateSplitPoints()
    }

    private mutating func finishSegmentMutation() {
        removedRanges = Self.mergeOverlapping(removedRanges.filter { $0.duration > 0.001 })
        pruneInvalidRemovedRanges()
    }

    private mutating func appendRemovedSpan(start: Double, end: Double) {
        let lo = min(start, end)
        let hi = max(start, end)
        guard hi - lo > 0.001 else { return }
        removedRanges.append(RemovedRange(startSeconds: lo, endSeconds: hi))
        removedRanges = Self.mergeOverlapping(removedRanges)
    }

    /// Extend kept content toward the end by shrinking removed ranges ending near `fromEnd`.
    private mutating func shrinkRemovedSpan(towardEndFrom fromEnd: Double, to newEnd: Double) {
        guard newEnd > fromEnd + 0.001 else { return }
        var updated: [RemovedRange] = []
        for range in removedRanges {
            if range.endSeconds >= fromEnd - 0.05 && range.startSeconds <= fromEnd + 0.05 {
                var adjusted = range
                adjusted.startSeconds = max(adjusted.startSeconds, newEnd)
                if adjusted.endSeconds - adjusted.startSeconds > 0.001 {
                    updated.append(adjusted)
                }
            } else if range.startSeconds >= fromEnd - 0.05 && range.endSeconds <= newEnd + 0.05 {
                continue
            } else if range.startSeconds < newEnd && range.endSeconds > fromEnd {
                var tail = range
                tail.startSeconds = max(tail.startSeconds, newEnd)
                if tail.endSeconds - tail.startSeconds > 0.001 {
                    updated.append(tail)
                }
                var head = range
                head.endSeconds = min(head.endSeconds, fromEnd)
                if head.endSeconds - head.startSeconds > 0.001 {
                    updated.append(head)
                }
            } else {
                updated.append(range)
            }
        }
        removedRanges = Self.mergeOverlapping(updated)
    }

    /// Extend kept content toward the start by shrinking removed ranges starting near `fromStart`.
    private mutating func shrinkRemovedSpan(towardStartFrom fromStart: Double, to newStart: Double) {
        guard newStart < fromStart - 0.001 else { return }
        var updated: [RemovedRange] = []
        for range in removedRanges {
            if range.startSeconds <= fromStart + 0.05 && range.endSeconds >= fromStart - 0.05 {
                var adjusted = range
                adjusted.endSeconds = min(adjusted.endSeconds, newStart)
                if adjusted.endSeconds - adjusted.startSeconds > 0.001 {
                    updated.append(adjusted)
                }
            } else if range.endSeconds <= fromStart + 0.05 && range.startSeconds >= newStart - 0.05 {
                continue
            } else if range.startSeconds < fromStart && range.endSeconds > newStart {
                var head = range
                head.endSeconds = min(head.endSeconds, newStart)
                if head.endSeconds - head.startSeconds > 0.001 {
                    updated.append(head)
                }
                var tail = range
                tail.startSeconds = max(tail.startSeconds, fromStart)
                if tail.endSeconds - tail.startSeconds > 0.001 {
                    updated.append(tail)
                }
            } else {
                updated.append(range)
            }
        }
        removedRanges = Self.mergeOverlapping(updated)
    }

    private mutating func pruneDegenerateSplitPoints() {
        let minSpan = Self.minimumSpanSeconds
        splitPoints = splitPoints.filter { point in
            point >= clampedTrimStart + minSpan && point <= clampedTrimEnd - minSpan
        }
    }

    private static func subtract(_ range: KeptSourceRange, by removed: RemovedRange) -> [KeptSourceRange] {
        if removed.endSeconds <= range.start || removed.startSeconds >= range.end {
            return [range]
        }
        var result: [KeptSourceRange] = []
        if removed.startSeconds > range.start {
            result.append(KeptSourceRange(start: range.start, end: removed.startSeconds))
        }
        if removed.endSeconds < range.end {
            result.append(KeptSourceRange(start: removed.endSeconds, end: range.end))
        }
        return result
    }

    private static func mergeOverlapping(_ ranges: [RemovedRange]) -> [RemovedRange] {
        guard !ranges.isEmpty else { return [] }
        let sorted = ranges.sorted { $0.startSeconds < $1.startSeconds }
        var merged: [RemovedRange] = [sorted[0]]
        for range in sorted.dropFirst() {
            var last = merged.removeLast()
            if range.startSeconds <= last.endSeconds + 0.001 {
                last.endSeconds = max(last.endSeconds, range.endSeconds)
                merged.append(last)
            } else {
                merged.append(last)
                merged.append(range)
            }
        }
        return merged
    }
}

struct VideoClipSegment: Identifiable {
    let id: Int
    let sourceStart: Double
    let sourceEnd: Double
    let splitIndexAtStart: Int?
    let splitIndexAtEnd: Int?
    let effectiveStart: Double
    let effectiveEnd: Double
    let hasGapBefore: Bool
    let hasGapAfter: Bool

    var effectiveDuration: Double { max(0, effectiveEnd - effectiveStart) }
}
