//
//  EditorTimelineView.swift
//  FrameFlow
//

import AppKit
import SwiftUI

struct EditorTimelineView: View {
    let duration: Double
    let trimStart: Double
    let trimEnd: Double
    let splitPoints: [Double]
    let currentTime: Double
    let trackWidth: CGFloat
    var razorModeActive: Bool = false
    let onTrimStartChange: (Double) -> Void
    let onTrimEndChange: (Double) -> Void
    let onSeek: (Double) -> Void
    let onRazorCut: (Double) -> Void
    let onMoveSplitPoint: (Int, Double) -> Void

    @State private var draggingHandle: DragHandle?
    @State private var razorHoverX: CGFloat?

    private enum DragHandle {
        case globalIn
        case globalOut
        case split(index: Int)
    }

    private var laneHeight: CGFloat { EditorTimelineLayout.mainTrackHeight }
    private var handleWidth: CGFloat { EditorTimelineLayout.trimHandleWidth }

    private var editTimeline: EditTimelineModel {
        var timeline = EditTimelineModel(
            sourceDurationSeconds: duration,
            trimStartSeconds: trimStart,
            trimEndSeconds: trimEnd
        )
        timeline.splitPoints = splitPoints
        return timeline
    }

    private var segments: [VideoClipSegment] {
        editTimeline.videoClipSegments()
    }

    var body: some View {
        ZStack(alignment: .leading) {
            interactionLayer

            keptRegions

            if razorModeActive, let razorHoverX {
                Rectangle()
                    .fill(EditorTimelineDesign.trimHandleYellow)
                    .frame(width: 1, height: laneHeight)
                    .offset(x: razorHoverX)
                    .allowsHitTesting(false)
            }

            playhead

            splitBoundaryHandles

            trimHandle(isLeading: true)
                .offset(x: xPosition(for: trimStart))
                .gesture(handleDragGesture(.globalIn))
                .zIndex(4)

            trimHandle(isLeading: false)
                .offset(x: xPosition(for: trimEnd) - handleWidth)
                .gesture(handleDragGesture(.globalOut))
                .zIndex(4)
        }
        .frame(width: trackWidth, height: laneHeight)
    }

    @ViewBuilder
    private var interactionLayer: some View {
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
        } else {
            layer.highPriorityGesture(scrubGesture)
        }
    }

    @ViewBuilder
    private var keptRegions: some View {
        if segments.isEmpty {
            segmentBody(from: trimStart, to: trimEnd, showBorder: false)
        } else {
            ForEach(segments) { segment in
                segmentBody(
                    from: segment.effectiveStart,
                    to: segment.effectiveEnd,
                    showBorder: true
                )
            }
        }
    }

    @ViewBuilder
    private var splitBoundaryHandles: some View {
        ForEach(Array(splitPoints.enumerated()), id: \.offset) { index, _ in
            if editTimeline.canMoveSplitBoundary(at: index) {
                trimHandle(isLeading: false)
                    .offset(x: xPosition(for: splitPoints[index]) - handleWidth / 2)
                    .gesture(handleDragGesture(.split(index: index)))
                    .zIndex(5)
            }
        }
    }

    private func segmentBody(from start: Double, to end: Double, showBorder: Bool) -> some View {
        let width = max(0, xPosition(for: end) - xPosition(for: start))
        return RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.14))
            .overlay {
                if showBorder {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(EditorTimelineDesign.clipBorderYellow, lineWidth: 2)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(EditorTimelineDesign.clipBorderYellow.opacity(0.35), lineWidth: 1)
                }
            }
            .frame(width: width, height: laneHeight - 8)
            .offset(x: xPosition(for: start))
            .frame(height: laneHeight, alignment: .center)
            .allowsHitTesting(false)
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

    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard draggingHandle == nil else { return }
                onSeek(timeAt(x: value.location.x))
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

    private func handleDragGesture(_ handle: DragHandle) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !razorModeActive else { return }
                if draggingHandle == nil {
                    draggingHandle = handle
                }
                let time = timeAt(x: value.location.x)
                switch handle {
                case .globalIn:
                    onTrimStartChange(time)
                case .globalOut:
                    onTrimEndChange(time)
                case .split(let index):
                    onMoveSplitPoint(index, time)
                }
            }
            .onEnded { _ in
                draggingHandle = nil
            }
    }

    private func xPosition(for time: Double) -> CGFloat {
        TimelineGeometry.xPosition(for: time, duration: duration, width: trackWidth)
    }

    private func timeAt(x: CGFloat) -> Double {
        TimelineGeometry.timeAt(x: x, duration: duration, width: trackWidth)
    }
}
