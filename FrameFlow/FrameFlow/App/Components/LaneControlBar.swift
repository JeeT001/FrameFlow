//
//  LaneControlBar.swift
//  FrameFlow
//

import SwiftUI

struct LaneControlBar: View {
    let laneName: String
    let laneHeight: CGFloat
    @Binding var isLocked: Bool
    @Binding var isMuted: Bool
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(laneName)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.55))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button { isLocked.toggle() } label: {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 10))
                    .foregroundStyle(isLocked ? Color.yellow : Color.white.opacity(0.5))
            }
            .buttonStyle(.borderless)
            .help(isLocked ? "Unlock lane" : "Lock lane")

            Button { isMuted.toggle() } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.1")
                    .font(.system(size: 10))
                    .foregroundStyle(isMuted ? Color.orange : Color.white.opacity(0.5))
            }
            .buttonStyle(.borderless)
            .help(isMuted ? "Unmute" : "Mute")

            Button { isVisible.toggle() } label: {
                Image(systemName: isVisible ? "eye" : "eye.slash")
                    .font(.system(size: 10))
                    .foregroundStyle(isVisible ? Color.white.opacity(0.5) : Color.orange)
            }
            .buttonStyle(.borderless)
            .help(isVisible ? "Hide lane" : "Show lane")
        }
        .padding(.horizontal, 6)
        .frame(width: EditorTimelineLayout.laneControlWidth, height: laneHeight)
        .background(Color.white.opacity(0.04))
    }
}
