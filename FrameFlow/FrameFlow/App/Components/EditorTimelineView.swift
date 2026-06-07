//
//  EditorTimelineView.swift
//  FrameFlow
//

import SwiftUI

struct EditorTimelineView: View {
    let duration: Double
    let trimStart: Double
    let trimEnd: Double
    let currentTime: Double
    let onTrimStartChange: (Double) -> Void
    let onTrimEndChange: (Double) -> Void
    let onSeek: (Double) -> Void

    @State private var draggingHandle: TrimHandle?

    private enum TrimHandle {
        case inPoint
        case outPoint
    }

    private let trackHeight: CGFloat = 8
    private let handleWidth: CGFloat = 14
    private let handleHeight: CGFloat = 28

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(durationReadout)
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppColors.textSecondary)

            GeometryReader { geometry in
                let width = max(geometry.size.width, 1)
                ZStack(alignment: .leading) {
                    trackBackground(width: width)

                    selectedRegion(width: width)

                    playhead(width: width)

                    trimHandle(isInPoint: true)
                        .offset(x: xPosition(for: trimStart, width: width) - handleWidth / 2)
                        .gesture(handleDragGesture(.inPoint, width: width))

                    trimHandle(isInPoint: false)
                        .offset(x: xPosition(for: trimEnd, width: width) - handleWidth / 2)
                        .gesture(handleDragGesture(.outPoint, width: width))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(scrubGesture(width: width))
            }
            .frame(height: 36)
        }
    }

    private var durationReadout: String {
        let trimmed = max(0, trimEnd - trimStart)
        return "\(TrimHelpers.formatTimelineTime(trimStart)) – \(TrimHelpers.formatTimelineTime(trimEnd)) " +
            "(\(TrimHelpers.formatTimelineTime(trimmed)))"
    }

    @ViewBuilder
    private func trackBackground(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(AppColors.border.opacity(0.45))
            .frame(width: width, height: trackHeight)

        if trimStart > 0 {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.18))
                .frame(width: xPosition(for: trimStart, width: width), height: trackHeight)
        }

        if trimEnd < duration {
            let trailingX = xPosition(for: trimEnd, width: width)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.18))
                .frame(width: width - trailingX, height: trackHeight)
                .offset(x: trailingX)
        }
    }

    private func selectedRegion(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(AppColors.primary.opacity(0.4))
            .frame(
                width: max(0, xPosition(for: trimEnd, width: width) - xPosition(for: trimStart, width: width)),
                height: trackHeight
            )
            .offset(x: xPosition(for: trimStart, width: width))
    }

    private func playhead(width: CGFloat) -> some View {
        Rectangle()
            .fill(AppColors.recRed)
            .frame(width: 2, height: handleHeight)
            .offset(x: xPosition(for: currentTime, width: width) - 1)
            .allowsHitTesting(false)
    }

    private func trimHandle(isInPoint: Bool) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(isInPoint ? AppColors.primary : AppColors.pauseYellow)
            .frame(width: handleWidth, height: handleHeight)
            .overlay {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 2, height: handleHeight * 0.45)
            }
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            .zIndex(1)
    }

    private func handleDragGesture(_ handle: TrimHandle, width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                draggingHandle = handle
                let time = timeAt(x: value.location.x, width: width)
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

    private func scrubGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard draggingHandle == nil else { return }
                onSeek(timeAt(x: value.location.x, width: width))
            }
    }

    private func xPosition(for time: Double, width: CGFloat) -> CGFloat {
        guard duration > 0 else { return 0 }
        let fraction = min(1, max(0, time / duration))
        return CGFloat(fraction) * width
    }

    private func timeAt(x: CGFloat, width: CGFloat) -> Double {
        guard width > 0, duration > 0 else { return 0 }
        let fraction = min(1, max(0, Double(x / width)))
        return fraction * duration
    }
}

#Preview {
    EditorTimelineView(
        duration: 92.5,
        trimStart: 12.3,
        trimEnd: 78.0,
        currentTime: 34.2,
        onTrimStartChange: { _ in },
        onTrimEndChange: { _ in },
        onSeek: { _ in }
    )
    .padding()
    .frame(width: 520)
}
