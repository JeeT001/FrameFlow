//
//  EditorTrimRangeSlider.swift
//  FrameFlow
//

import AppKit
import SwiftUI

struct EditorTrimRangeSlider: View {
    let duration: Double
    let trimStart: Double
    let trimEnd: Double
    let currentTime: Double
    let trackWidth: CGFloat
    let onTrimStartChange: (Double) -> Void
    let onTrimEndChange: (Double) -> Void
    let onSeek: (Double) -> Void

    @State private var draggingHandle: TrimHandle?
    @State private var hoverHandle: TrimHandle?

    private enum TrimHandle {
        case inPoint
        case outPoint
    }

    private let trackHeight: CGFloat = 28
    private let thumbWidth: CGFloat = 9
    private let thumbHitWidth: CGFloat = 24

    private var thumbBodyHeight: CGFloat { trackHeight - 4 }

    var body: some View {
        ZStack(alignment: .leading) {
            interactionLayer

            trackBackground

            excludedOverlay(from: 0, width: xPosition(for: trimStart))

            let selectedWidth = max(0, xPosition(for: trimEnd) - xPosition(for: trimStart))
            selectedRange(width: selectedWidth)
                .offset(x: xPosition(for: trimStart))

            excludedOverlay(from: xPosition(for: trimEnd), width: max(0, trackWidth - xPosition(for: trimEnd)))

            playhead

            trimThumb(isLeading: true)
                .offset(x: xPosition(for: trimStart) - thumbHitWidth / 2)
                .gesture(handleDragGesture(.inPoint))
                .zIndex(4)

            trimThumb(isLeading: false)
                .offset(x: xPosition(for: trimEnd) - thumbHitWidth / 2)
                .gesture(handleDragGesture(.outPoint))
                .zIndex(4)
        }
        .frame(width: trackWidth, height: trackHeight)
    }

    private var trackBackground: some View {
        Capsule()
            .fill(Color.white.opacity(0.08))
            .frame(width: trackWidth, height: trackHeight)
            .allowsHitTesting(false)
    }

    private func excludedOverlay(from x: CGFloat, width: CGFloat) -> some View {
        Capsule()
            .fill(Color.black.opacity(0.35))
            .frame(width: width, height: trackHeight)
            .offset(x: x)
            .allowsHitTesting(false)
    }

    private func selectedRange(width: CGFloat) -> some View {
        Capsule()
            .fill(AppColors.primary.opacity(0.22))
            .overlay {
                Capsule()
                    .strokeBorder(AppColors.primary, lineWidth: 1.5)
            }
            .frame(width: width, height: trackHeight)
            .allowsHitTesting(false)
    }

    private var playhead: some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 1.5, height: trackHeight - 6)
            .offset(x: xPosition(for: currentTime) - 0.75)
            .allowsHitTesting(false)
    }

    private func trimThumb(isLeading: Bool) -> some View {
        let isHovered = hoverHandle == (isLeading ? .inPoint : .outPoint)

        return ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(AppColors.primary)
                .frame(width: thumbWidth, height: thumbBodyHeight)

            Image(systemName: isLeading ? "chevron.left" : "chevron.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.9))
        }
        .frame(width: thumbHitWidth, height: trackHeight)
        .contentShape(Rectangle())
        .onContinuousHover { phase in
            switch phase {
            case .active:
                hoverHandle = isLeading ? .inPoint : .outPoint
                NSCursor.resizeLeftRight.push()
            case .ended:
                if hoverHandle == (isLeading ? .inPoint : .outPoint) {
                    hoverHandle = nil
                }
                NSCursor.pop()
            }
        }
        .opacity(isHovered || draggingHandle == (isLeading ? .inPoint : .outPoint) ? 1 : 0.95)
    }

    private var interactionLayer: some View {
        Color.clear
            .frame(width: trackWidth, height: trackHeight)
            .contentShape(Rectangle())
            .help("Drag to scrub")
            .highPriorityGesture(scrubGesture)
            .simultaneousGesture(tapSeekGesture)
    }

    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard draggingHandle == nil else { return }
                onSeek(timeAt(x: value.location.x))
            }
    }

    private var tapSeekGesture: some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                guard draggingHandle == nil else { return }
                onSeek(timeAt(x: value.location.x))
            }
    }

    private func handleDragGesture(_ handle: TrimHandle) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if draggingHandle == nil {
                    draggingHandle = handle
                }
                let time = timeAt(x: value.location.x)
                switch handle {
                case .inPoint:
                    onTrimStartChange(time)
                case .outPoint:
                    onTrimEndChange(time)
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
