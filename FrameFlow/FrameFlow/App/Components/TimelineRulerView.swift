//
//  TimelineRulerView.swift
//  FrameFlow
//

import SwiftUI

struct TimelineRulerView: View {
    let totalDuration: Double
    let trackWidth: CGFloat
    let timelineZoom: Double
    let playheadSeconds: Double

    private var effectiveWidth: CGFloat {
        EditorTimelineLayout.effectiveTrackWidth(baseWidth: trackWidth, zoom: timelineZoom)
    }

    private var pixelsPerSecond: CGFloat {
        guard totalDuration > 0 else { return 0 }
        return effectiveWidth / CGFloat(totalDuration)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.5)

            ForEach(tickTimes(), id: \.self) { time in
                let x = CGFloat(time) * pixelsPerSecond
                let majorInterval = majorTickInterval
                let isMajor = time.truncatingRemainder(dividingBy: majorInterval) < 0.01
                    || abs(time - totalDuration) < 0.01

                Rectangle()
                    .fill(Color.white.opacity(isMajor ? 0.6 : 0.25))
                    .frame(width: 1, height: isMajor ? 12 : 6)
                    .offset(x: x, y: isMajor ? 0 : 6)

                if isMajor {
                    Text(formatTimecode(time))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .offset(x: x + 3, y: 0)
                }
            }
        }
        .frame(width: effectiveWidth, height: EditorTimelineDesign.timelineRulerHeight)
    }

    private var majorTickInterval: Double {
        if totalDuration > 300 { return 60 }
        if totalDuration > 60 { return 10 }
        return 5
    }

    private func tickTimes() -> [Double] {
        let minorInterval = majorTickInterval / 5
        guard minorInterval > 0, totalDuration > 0 else { return [0] }
        var times: [Double] = []
        var t = 0.0
        while t <= totalDuration + 0.001 {
            times.append(t)
            t += minorInterval
        }
        return times
    }

    private func formatTimecode(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}
