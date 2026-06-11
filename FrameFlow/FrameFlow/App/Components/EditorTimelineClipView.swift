//
//  EditorTimelineClipView.swift
//  FrameFlow
//

import SwiftUI

enum EditorTimelineClipKind {
    case overlay
    case audio
}

struct EditorTimelineClipView: View {
    let startTime: Double
    let endTime: Double
    let totalDuration: Double
    let trackWidth: CGFloat
    let minClipDuration: Double
    let label: String
    let kind: EditorTimelineClipKind
    var isSelected: Bool = false
    var isActiveAtPlayhead: Bool = false
    var isLocked: Bool = false
    var isHidden: Bool = false
    var audioFileURL: URL?
    let onStartChange: (Double) -> Void
    let onEndChange: (Double) -> Void
    let onMoveStart: (Double) -> Void
    let onSelect: () -> Void

    @State private var dragAnchorStart: Double?
    @State private var dragAnchorEnd: Double?
    @State private var dragMode: DragMode?

    private enum DragMode {
        case move
        case trimStart
        case trimEnd
    }

    private var handleWidth: CGFloat { EditorTimelineLayout.clipTrimHandleWidth }
    private var handleHitWidth: CGFloat { EditorTimelineLayout.clipTrimHandleHitWidth }
    private var laneHeight: CGFloat {
        kind == .audio ? EditorTimelineLayout.audioLaneHeight : EditorTimelineLayout.clipLaneHeight
    }

    private var fillColor: Color {
        switch kind {
        case .overlay: EditorTimelineDesign.overlayBlue
        case .audio: EditorTimelineDesign.audioGreen
        }
    }

    private var handleColor: Color {
        switch kind {
        case .overlay: .blue
        case .audio: .green
        }
    }

    var body: some View {
        let clipX = TimelineGeometry.xPosition(for: startTime, duration: totalDuration, width: trackWidth)
        let clipEndX = TimelineGeometry.xPosition(for: endTime, duration: totalDuration, width: trackWidth)
        let clipWidth = max(handleWidth + 4, clipEndX - clipX)

        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(fillColor)
                .overlay {
                    if kind == .audio, let audioFileURL {
                        AudioWaveformView(
                            url: audioFileURL,
                            width: max(clipWidth - handleWidth * 2, 1),
                            height: laneHeight - 4
                        )
                        .padding(.horizontal, handleWidth)
                    } else if kind == .audio {
                        EditorAudioWaveformShape()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            .padding(.horizontal, handleWidth + 2)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(
                            isSelected ? EditorTimelineDesign.clipBorderYellow : Color.clear,
                            lineWidth: 1.5
                        )
                }
                .frame(width: clipWidth, height: laneHeight)
                .opacity(isHidden ? 0.35 : 1)
                .overlay {
                    Text(label)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(1)
                        .padding(.horizontal, handleWidth + 2)
                }
                .offset(x: clipX)
                .allowsHitTesting(!isLocked)
                .gesture(bodyDragGesture())
                .onTapGesture { onSelect() }

            if !isLocked {
                trimHandle(isLeading: true)
                    .offset(x: clipX)
                    .zIndex(2)
                    .highPriorityGesture(trimStartGesture())

                trimHandle(isLeading: false)
                    .offset(x: clipX + clipWidth - handleWidth)
                    .zIndex(2)
                    .highPriorityGesture(trimEndGesture())
            }
        }
        .frame(width: trackWidth, height: laneHeight, alignment: .leading)
    }

    private func trimHandle(isLeading: Bool) -> some View {
        EditorTimelineTrimHandle(
            isLeading: isLeading,
            width: handleWidth,
            height: laneHeight - 2,
            fillColor: handleColor,
            hitWidth: handleHitWidth
        )
        .onHover { inside in
            if inside {
                NSCursor.resizeLeftRight.push()
            } else {
                NSCursor.pop()
            }
        }
        .help(isLeading ? "Trim clip start" : "Trim clip end")
    }

    private func bodyDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if dragMode == nil {
                    dragMode = .move
                    dragAnchorStart = startTime
                }
                guard dragMode == .move,
                      let anchorStart = dragAnchorStart else { return }
                let delta = TimelineGeometry.timeAt(
                    x: value.translation.width,
                    duration: totalDuration,
                    width: trackWidth
                )
                onMoveStart(anchorStart + delta)
            }
            .onEnded { _ in
                dragAnchorStart = nil
                dragAnchorEnd = nil
                dragMode = nil
            }
    }

    private func trimStartGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragMode == nil {
                    dragMode = .trimStart
                    dragAnchorStart = startTime
                }
                guard dragMode == .trimStart, let anchor = dragAnchorStart else { return }
                let delta = TimelineGeometry.timeAt(
                    x: value.translation.width,
                    duration: totalDuration,
                    width: trackWidth
                )
                let maxStart = endTime - minClipDuration
                onStartChange(min(max(anchor + delta, 0), maxStart))
            }
            .onEnded { _ in
                dragAnchorStart = nil
                dragMode = nil
            }
    }

    private func trimEndGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragMode == nil {
                    dragMode = .trimEnd
                    dragAnchorEnd = endTime
                }
                guard dragMode == .trimEnd, let anchor = dragAnchorEnd else { return }
                let delta = TimelineGeometry.timeAt(
                    x: value.translation.width,
                    duration: totalDuration,
                    width: trackWidth
                )
                let minEnd = startTime + minClipDuration
                onEndChange(min(max(anchor + delta, minEnd), totalDuration))
            }
            .onEnded { _ in
                dragAnchorEnd = nil
                dragMode = nil
            }
    }
}
