//
//  EditorTimelineView.swift
//  FrameFlow
//

import AppKit
import SwiftUI

struct EditorTimelineView: View {
    let videoURL: URL
    let duration: Double
    let trimStart: Double
    let trimEnd: Double
    let exportDurationSeconds: Double
    let removedRanges: [RemovedRange]
    let splitPoints: [Double]
    var segmentOrder: [Int] = []
    let selectionStart: Double?
    let selectionEnd: Double?
    let currentTime: Double
    let trackWidth: CGFloat
    var showsPlayhead: Bool = true
    var scrubDuration: Double?
    var clipLabel: String = "Video"
    var razorModeActive: Bool = false
    var isLaneLocked: Bool = false
    var isLaneVisible: Bool = true
    let onTrimStartChange: (Double) -> Void
    let onTrimEndChange: (Double) -> Void
    let onSelectionStartChange: (Double) -> Void
    let onSelectionEndChange: (Double) -> Void
    let onSeek: (Double) -> Void
    let onRazorCut: (Double) -> Void
    let onTrimSegmentOut: (Int, Double) -> Void
    let onTrimSegmentIn: (Int, Double) -> Void
    let onExtendSegmentOut: (Int, Double) -> Void
    let onExtendSegmentIn: (Int, Double) -> Void
    let onRippleCloseGap: (Int, Int, Double) -> Void
    let onMoveSplitPoint: (Int, Double) -> Void
    var onReorderSegment: ((Int, Int) -> Void)? = nil

    @State private var draggingHandle: DragHandle?
    @State private var dragAnchorEffectiveStart: Double?
    @State private var dragAnchorEffectiveEnd: Double?
    @State private var razorHoverX: CGFloat?
    @State private var draggingSegmentIndex: Int?
    @State private var dragOffsetX: CGFloat = 0
    @State private var dragTargetIndex: Int?

    private enum DragHandle {
        case globalIn
        case globalOut
        case segmentIn(segmentID: Int)
        case segmentOut(segmentID: Int)
    }

    private var laneHeight: CGFloat { EditorTimelineLayout.mainTrackHeight }
    private var handleWidth: CGFloat { EditorTimelineLayout.trimHandleWidth }
    private var clipContentHeight: CGFloat {
        EditorTimelineDesign.filmstripHeight + EditorTimelineDesign.waveformBarHeight
    }

    private var editTimeline: EditTimelineModel {
        var timeline = EditTimelineModel(
            sourceDurationSeconds: duration,
            trimStartSeconds: trimStart,
            trimEndSeconds: trimEnd,
            removedRanges: removedRanges
        )
        timeline.splitPoints = splitPoints
        timeline.segmentOrder = segmentOrder
        return timeline
    }

    private var segments: [VideoClipSegment] {
        editTimeline.videoClipSegments()
    }

    private var orderedRanges: [KeptSourceRange] {
        editTimeline.orderedSourceRanges
    }

    private var canReorderSegments: Bool {
        editTimeline.segmentSourceRanges.count >= 2
    }

    private var pixelsPerSecond: CGFloat {
        guard exportDurationSeconds > 0.001 else { return 0 }
        return trackWidth / CGFloat(exportDurationSeconds)
    }

    @ViewBuilder
    var body: some View {
        Group {
            if isLaneVisible {
                timelineContent
            } else {
                timelineContent.opacity(0.35)
            }
        }
    }

    private var timelineContent: some View {
        ZStack(alignment: .leading) {
            scrubInteractionLayer

            ForEach(Array(removedRanges.enumerated()), id: \.offset) { _, removed in
                removedRegion(removed)
            }

            keptRegions

            pendingSelectionRegion

            if showsPlayhead {
                playhead
            }

            if razorModeActive, let razorHoverX {
                Rectangle()
                    .fill(EditorTimelineDesign.trimHandleYellow)
                    .frame(width: 1, height: laneHeight)
                    .offset(x: razorHoverX)
                    .allowsHitTesting(false)
            }

            segmentHandles

            if !isLaneLocked, !canReorderSegments {
                trimHandle(isLeading: true)
                    .offset(x: xPosition(for: trimStart))
                    .gesture(handleDragGesture(.globalIn))
                    .zIndex(4)

                trimHandle(isLeading: false)
                    .offset(x: xPosition(for: trimEnd) - handleWidth)
                    .gesture(handleDragGesture(.globalOut))
                    .zIndex(4)
            }
        }
        .coordinateSpace(name: "videoLane")
        .frame(width: trackWidth, height: laneHeight)
    }

    @ViewBuilder
    private var scrubInteractionLayer: some View {
        let layer = Color.clear
            .frame(width: trackWidth, height: laneHeight)
            .contentShape(Rectangle())
            .help(razorModeActive ? "Click to cut" : "Drag to scrub")
            .onContinuousHover { phase in
                guard razorModeActive else {
                    razorHoverX = nil
                    return
                }
                switch phase {
                case .active(let location):
                    razorHoverX = location.x
                    NSCursor.crosshair.push()
                case .ended:
                    razorHoverX = nil
                    NSCursor.pop()
                }
            }

        if razorModeActive {
            layer.highPriorityGesture(razorTapGesture)
        } else if !isLaneLocked, draggingSegmentIndex == nil {
            layer.highPriorityGesture(scrubGesture)
        } else {
            layer
        }
    }

    @ViewBuilder
    private var keptRegions: some View {
        if canReorderSegments {
            ForEach(Array(orderedRanges.enumerated()), id: \.offset) { displayIndex, range in
                orderedSegmentView(displayIndex: displayIndex, range: range)
            }
        } else if segments.isEmpty {
            keptClipBody(from: trimStart, to: trimEnd)
        } else {
            ForEach(segments) { segment in
                keptClipBody(from: segment.effectiveStart, to: segment.effectiveEnd)
            }
        }
    }

    @ViewBuilder
    private var segmentHandles: some View {
        if !isLaneLocked {
            if canReorderSegments {
                ForEach(Array(orderedRanges.enumerated()), id: \.offset) { displayIndex, range in
                    if let segment = segmentMatching(range) {
                        if showsSegmentInHandle(segment) {
                            trimHandle(isLeading: true)
                                .offset(x: orderedSegmentX(displayIndex))
                                .gesture(handleDragGesture(.segmentIn(segmentID: segment.id)))
                                .zIndex(5)
                        }

                        if showsSegmentOutHandle(segment) {
                            let segmentW = CGFloat(range.duration) * pixelsPerSecond
                            trimHandle(isLeading: false)
                                .offset(x: orderedSegmentX(displayIndex) + segmentW - handleWidth)
                                .gesture(handleDragGesture(.segmentOut(segmentID: segment.id)))
                                .zIndex(5)
                        }
                    }
                }
            } else {
                ForEach(segments) { segment in
                    if showsSegmentInHandle(segment) {
                        trimHandle(isLeading: true)
                            .offset(x: xPosition(for: segment.effectiveStart))
                            .gesture(handleDragGesture(.segmentIn(segmentID: segment.id)))
                            .zIndex(5)
                    }

                    if showsSegmentOutHandle(segment) {
                        trimHandle(isLeading: false)
                            .offset(x: xPosition(for: segment.effectiveEnd) - handleWidth)
                            .gesture(handleDragGesture(.segmentOut(segmentID: segment.id)))
                            .zIndex(5)
                    }
                }
            }
        }
    }

    private func orderedSegmentView(displayIndex: Int, range: KeptSourceRange) -> some View {
        let segmentW = max(1, CGFloat(range.duration) * pixelsPerSecond)
        let segmentX = orderedSegmentX(displayIndex)
        let isDragging = draggingSegmentIndex == displayIndex
        let offsetX = isDragging ? dragOffsetX : 0

        return ZStack {
            EditorFilmstripClipView(
                videoURL: videoURL,
                clipWidthPixels: segmentW,
                trimStart: range.start,
                trimEnd: range.end,
                clipLabel: clipLabel
            )
            .allowsHitTesting(false)

            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    isDragging
                        ? Color.white.opacity(0.9)
                        : EditorTimelineDesign.clipBorderYellow,
                    lineWidth: 2
                )
                .allowsHitTesting(false)

            if dragTargetIndex == displayIndex, draggingSegmentIndex != displayIndex {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.12))
                    .allowsHitTesting(false)
            }
        }
        .frame(width: segmentW, height: laneHeight)
        .scaleEffect(y: isDragging ? 0.92 : 1, anchor: .center)
        .shadow(color: isDragging ? .black.opacity(0.4) : .clear, radius: 8, y: 4)
        .offset(x: segmentX + offsetX)
        .zIndex(isDragging ? 10 : 2)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: draggingSegmentIndex)
        .contentShape(Rectangle())
        .help("Drag to reorder")
        .modifier(
            SegmentReorderGestureModifier(
                isEnabled: !isLaneLocked && !razorModeActive,
                gesture: segmentDragGesture(displayIndex: displayIndex, segmentW: segmentW)
            )
        )
    }

    private func segmentDragGesture(displayIndex: Int, segmentW: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .named("videoLane"))
            .onChanged { value in
                if draggingSegmentIndex == nil {
                    draggingSegmentIndex = displayIndex
                }
                dragOffsetX = value.translation.width

                let originX = orderedSegmentX(displayIndex)
                let centerX = originX + segmentW / 2 + dragOffsetX
                dragTargetIndex = segmentIndexAt(centerX: centerX)
            }
            .onEnded { value in
                if let from = draggingSegmentIndex {
                    let ranges = orderedRanges
                    if from < ranges.count {
                        let originX = orderedSegmentX(from)
                        let draggedWidth = CGFloat(ranges[from].duration) * pixelsPerSecond
                        let centerX = originX + draggedWidth / 2 + value.translation.width
                        let to = segmentIndexAt(centerX: centerX)
                        if from != to {
                            onReorderSegment?(from, to)
                        }
                    }
                }
                withAnimation(.spring(response: 0.2)) {
                    draggingSegmentIndex = nil
                    dragOffsetX = 0
                    dragTargetIndex = nil
                }
            }
    }

    private func orderedSegmentX(_ displayIndex: Int) -> CGFloat {
        (0..<displayIndex).reduce(0) { partial, index in
            partial + CGFloat(orderedRanges[index].duration) * pixelsPerSecond
        }
    }

    private func segmentIndexAt(centerX: CGFloat) -> Int {
        var x: CGFloat = 0
        for (index, range) in orderedRanges.enumerated() {
            let width = CGFloat(range.duration) * pixelsPerSecond
            if centerX < x + width { return index }
            x += width
        }
        return max(0, orderedRanges.count - 1)
    }

    private func segmentMatching(_ range: KeptSourceRange) -> VideoClipSegment? {
        segments.first {
            abs($0.effectiveStart - range.start) < 0.05 && abs($0.effectiveEnd - range.end) < 0.05
        }
    }

    private func showsSegmentInHandle(_ segment: VideoClipSegment) -> Bool {
        if abs(segment.effectiveStart - trimStart) < 0.05, segment.splitIndexAtStart == nil {
            return false
        }
        return true
    }

    private func showsSegmentOutHandle(_ segment: VideoClipSegment) -> Bool {
        if abs(segment.effectiveEnd - trimEnd) < 0.05, segment.splitIndexAtEnd == nil {
            return false
        }
        return true
    }

    private func keptClipBody(from start: Double, to end: Double) -> some View {
        let width = max(0, xPosition(for: end) - xPosition(for: start))
        return EditorFilmstripClipView(
            videoURL: videoURL,
            clipWidthPixels: width,
            trimStart: start,
            trimEnd: end,
            clipLabel: clipLabel
        )
        .frame(width: width, height: clipContentHeight)
        .offset(x: xPosition(for: start))
        .frame(height: laneHeight, alignment: .center)
        .allowsHitTesting(false)
    }

    private func removedRegion(_ removed: RemovedRange) -> some View {
        let width = max(0, xPosition(for: removed.endSeconds) - xPosition(for: removed.startSeconds))
        return Color.black.opacity(0.5)
            .frame(width: width, height: laneHeight)
            .offset(x: xPosition(for: removed.startSeconds))
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var pendingSelectionRegion: some View {
        if let selectionStart,
           let selectionEnd {
            let lo = min(selectionStart, selectionEnd)
            let hi = max(selectionStart, selectionEnd)
            EditorTimelineDesign.trimHandleYellow.opacity(0.2)
                .frame(
                    width: max(0, xPosition(for: hi) - xPosition(for: lo)),
                    height: laneHeight
                )
                .offset(x: xPosition(for: lo))
                .allowsHitTesting(false)
        }
    }

    private var playhead: some View {
        EditorTimelinePlayheadMarker(
            color: .white,
            lineHeight: laneHeight - EditorTimelineDesign.playheadTriangleHeight
        )
        .offset(x: xPosition(for: currentTime) - EditorTimelineDesign.playheadTriangleWidth / 2)
        .allowsHitTesting(false)
    }

    private func trimHandle(isLeading: Bool) -> some View {
        EditorFilmstripTrimHandle(isLeading: isLeading, height: laneHeight)
    }

    private func handleDragGesture(_ handle: DragHandle) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !razorModeActive else { return }
                if draggingHandle == nil {
                    draggingHandle = handle
                    if case .segmentIn(let id) = handle,
                       let segment = segments.first(where: { $0.id == id }) {
                        dragAnchorEffectiveStart = segment.effectiveStart
                    }
                    if case .segmentOut(let id) = handle,
                       let segment = segments.first(where: { $0.id == id }) {
                        dragAnchorEffectiveEnd = segment.effectiveEnd
                    }
                }
                let time = timeAt(x: value.location.x)
                routeHandleDrag(handle, time: time)
            }
            .onEnded { _ in
                draggingHandle = nil
                dragAnchorEffectiveStart = nil
                dragAnchorEffectiveEnd = nil
            }
    }

    private func routeHandleDrag(_ handle: DragHandle, time: Double) {
        switch handle {
        case .globalIn:
            onTrimStartChange(time)
        case .globalOut:
            onTrimEndChange(time)
        case .segmentIn(let segmentID):
            routeSegmentInDrag(segmentID: segmentID, time: time)
        case .segmentOut(let segmentID):
            routeSegmentOutDrag(segmentID: segmentID, time: time)
        }
    }

    private func routeSegmentOutDrag(segmentID: Int, time: Double) {
        guard let segment = segments.first(where: { $0.id == segmentID }) else { return }
        let anchor = dragAnchorEffectiveEnd ?? segment.effectiveEnd
        let epsilon = 0.02

        if time < anchor - epsilon {
            onTrimSegmentOut(segmentID, time)
        } else if time > anchor + epsilon {
            if segment.hasGapAfter {
                onExtendSegmentOut(segmentID, time)
            } else if let splitIndex = segment.splitIndexAtEnd,
                      editTimeline.canMoveSplitBoundary(at: splitIndex) {
                onMoveSplitPoint(splitIndex, time)
            }
        }
    }

    private func routeSegmentInDrag(segmentID: Int, time: Double) {
        guard let segment = segments.first(where: { $0.id == segmentID }) else { return }
        let anchor = dragAnchorEffectiveStart ?? segment.effectiveStart
        let epsilon = 0.02

        if time > anchor + epsilon {
            onTrimSegmentIn(segmentID, time)
        } else if time < anchor - epsilon {
            if segment.hasGapBefore, let leftNeighbor = leftNeighbor(of: segment) {
                onRippleCloseGap(leftNeighbor.id, segmentID, time)
            } else if segment.hasGapBefore {
                onExtendSegmentIn(segmentID, time)
            } else if let splitIndex = segment.splitIndexAtStart,
                      editTimeline.canMoveSplitBoundary(at: splitIndex) {
                onMoveSplitPoint(splitIndex, time)
            }
        }
    }

    private func leftNeighbor(of segment: VideoClipSegment) -> VideoClipSegment? {
        segments
            .filter { $0.sourceEnd <= segment.sourceStart + 0.001 || $0.splitIndexAtEnd == segment.splitIndexAtStart }
            .sorted { $0.effectiveStart < $1.effectiveStart }
            .last { $0.id != segment.id && $0.effectiveEnd <= segment.effectiveStart + 0.05 }
    }

    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                guard draggingHandle == nil, draggingSegmentIndex == nil, !razorModeActive else { return }
                onSeek(scrubTimeAt(x: value.location.x))
            }
    }

    private var razorTapGesture: some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                guard draggingHandle == nil else { return }
                let seconds = timeAt(x: value.location.x)
                let snapped = CaptionTimelineMapper.snapToKeptSourceTime(seconds, editTimeline: editTimeline)
                onRazorCut(snapped)
            }
    }

    private func xPosition(for time: Double) -> CGFloat {
        TimelineGeometry.xPosition(for: time, duration: duration, width: trackWidth)
    }

    private func timeAt(x: CGFloat) -> Double {
        TimelineGeometry.timeAt(x: x, duration: duration, width: trackWidth)
    }

    private func scrubTimeAt(x: CGFloat) -> Double {
        let scrubTotal = scrubDuration ?? duration
        return TimelineGeometry.timeAt(x: x, duration: scrubTotal, width: trackWidth)
    }
}

private struct SegmentReorderGestureModifier<G: Gesture>: ViewModifier {
    let isEnabled: Bool
    let gesture: G

    func body(content: Content) -> some View {
        if isEnabled {
            content.highPriorityGesture(gesture)
        } else {
            content
        }
    }
}
