//
//  EditorTimelineDesign.swift
//  FrameFlow
//

import SwiftUI

/// Shared iMovie-style tokens for the editor timeline and chrome.
enum EditorTimelineDesign {
    static let panelBG = Color.white.opacity(0.04)
    static let timelineRulerBG = Color.black.opacity(0.4)

    static let trimHandleYellow = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let clipBorderYellow = trimHandleYellow
    static let overlayBlue = Color.blue.opacity(0.3)
    static let audioGreen = Color.green.opacity(0.3)
    static let cutRed = Color(red: 0.6, green: 0.1, blue: 0.1)

    static let timelineBackground = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let laneRowPrimaryBG = Color.white.opacity(0.03)
    static let laneRowSecondaryBG = Color.white.opacity(0.01)

    static let videoLaneHeight: CGFloat = 72
    static let filmstripHeight: CGFloat = 54
    static let waveformBarHeight: CGFloat = 14
    static let overlayLaneHeight: CGFloat = 36
    static let audioLaneHeight: CGFloat = 36
    static let trimHandleWidth: CGFloat = 12
    static let clipBorderWidth: CGFloat = 2
    static let overlayAudioHandleWidth: CGFloat = 6
    static let playheadWidth: CGFloat = 1.5
    static let playheadTriangleWidth: CGFloat = 12
    static let playheadTriangleHeight: CGFloat = 10
    static let laneLeftLabelWidth: CGFloat = 0
    static let timelineRulerHeight: CGFloat = 24
    static let laneDividerThickness: CGFloat = 1
    static let toolbarHeight: CGFloat = 36
    static let toolbarRowGap: CGFloat = 4
    static let filmoraToolbarHeight: CGFloat = toolbarHeight * 2 + toolbarRowGap
    static let tracksOuterPadding: CGFloat = 8
    static let trimHandleHitOutset: CGFloat = 8

    static let monoFont = Font.system(.caption2, design: .monospaced)
    static let sectionHeader = Font.system(size: 11, weight: .medium).smallCaps()
}

struct EditorPlayheadTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct EditorFilmstripTrimHandle: View {
    let isLeading: Bool
    let height: CGFloat

    private var width: CGFloat { EditorTimelineDesign.trimHandleWidth }
    private var hitWidth: CGFloat { width + EditorTimelineDesign.trimHandleHitOutset * 2 }

    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: isLeading ? 3 : 0,
            bottomLeadingRadius: isLeading ? 3 : 0,
            bottomTrailingRadius: isLeading ? 0 : 3,
            topTrailingRadius: isLeading ? 0 : 3
        )
        .fill(EditorTimelineDesign.trimHandleYellow)
        .frame(width: width, height: height)
        .overlay {
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 1, height: height * 0.52)
                }
            }
        }
        .frame(width: hitWidth, height: height)
        .contentShape(Rectangle())
        .onHover { inside in
            if inside {
                NSCursor.resizeLeftRight.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

struct EditorTimelinePlayheadMarker: View {
    let color: Color
    let lineHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            EditorPlayheadTriangle()
                .fill(color)
                .frame(
                    width: EditorTimelineDesign.playheadTriangleWidth,
                    height: EditorTimelineDesign.playheadTriangleHeight
                )

            Rectangle()
                .fill(color)
                .frame(width: EditorTimelineDesign.playheadWidth, height: lineHeight)
        }
    }
}

struct EditorTimelineTrimHandle: View {
    let isLeading: Bool
    let width: CGFloat
    let height: CGFloat
    let fillColor: Color
    var hitWidth: CGFloat?

    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: isLeading ? 3 : 0,
            bottomLeadingRadius: isLeading ? 3 : 0,
            bottomTrailingRadius: isLeading ? 0 : 3,
            topTrailingRadius: isLeading ? 0 : 3
        )
        .fill(fillColor)
        .frame(width: width, height: height)
        .overlay {
            HStack(spacing: 4) {
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 1, height: height * 0.55)
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 1, height: height * 0.55)
            }
        }
        .frame(width: hitWidth ?? width, height: height)
        .contentShape(Rectangle())
    }
}

struct EditorTimelineRulerView: View {
    let duration: Double
    let trackWidth: CGFloat
    let labelColumnWidth: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            EditorTimelineDesign.timelineRulerBG

            Canvas { context, size in
                guard duration > 0 else { return }
                let totalSeconds = Int(ceil(duration))
                for second in 0...totalSeconds {
                    let x = TimelineGeometry.xPosition(
                        for: Double(second),
                        duration: duration,
                        width: size.width
                    )
                    let isMajor = second % 5 == 0
                    let tickHeight: CGFloat = isMajor ? 10 : 5
                    var tick = Path()
                    tick.move(to: CGPoint(x: x, y: size.height - tickHeight))
                    tick.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(
                        tick,
                        with: .color(Color.white.opacity(isMajor ? 0.55 : 0.28)),
                        lineWidth: 1
                    )

                    if isMajor, second <= totalSeconds {
                        let label = formatRulerLabel(Double(second))
                        context.draw(
                            Text(label)
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.5)),
                            at: CGPoint(x: x + 2, y: 6)
                        )
                    }
                }
            }
        }
        .frame(width: trackWidth, height: EditorTimelineDesign.timelineRulerHeight)
        .frame(height: EditorTimelineDesign.timelineRulerHeight)
    }

    private func formatRulerLabel(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let secs = total % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        }
        return "\(secs)s"
    }
}

struct EditorAudioWaveformShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let amplitude = rect.height * 0.22
        let wavelength = rect.width / 8
        guard wavelength > 0 else { return path }

        path.move(to: CGPoint(x: 0, y: midY))
        var x: CGFloat = 0
        while x <= rect.width {
            let y = midY + sin(x / wavelength * .pi * 2) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += 2
        }
        return path
    }
}
