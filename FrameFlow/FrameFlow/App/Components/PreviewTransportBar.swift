//
//  PreviewTransportBar.swift
//  FrameFlow
//

import SwiftUI

struct PreviewTransportBar: View {
    @Binding var currentTime: Double
    let duration: Double
    let isPlaying: Bool
    let onSkipBack: () -> Void
    let onSlowMotion: () -> Void
    let onPlayPause: () -> Void
    let onStop: () -> Void
    let onSetInPoint: () -> Void
    let onSetOutPoint: () -> Void
    let onSnapshot: () -> Void
    let onFullscreen: () -> Void

    @State private var selectedQuality = "Full Quality"
    @State private var isPIP = false

    private let qualityOptions = ["Full Quality", "1/2 Quality", "1/4 Quality"]

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(formatTimecode(currentTime))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                Text("/")
                    .foregroundStyle(.white.opacity(0.3))
                Text(formatTimecode(duration))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                Picker("", selection: $selectedQuality) {
                    ForEach(qualityOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(width: 120)
            }

            Slider(
                value: $currentTime,
                in: 0...max(duration, 0.01)
            )
            .tint(Color(red: 0.95, green: 0.2, blue: 0.2))

            HStack(spacing: 16) {
                Button(action: onSkipBack) {
                    Image(systemName: "backward.end.fill")
                }
                .help("Jump to start")

                Button(action: onSlowMotion) {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                }
                .help("Slow motion")

                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                }
                .help(isPlaying ? "Pause" : "Play")

                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                }
                .help("Stop")

                Divider().frame(height: 16)

                Button(action: onSetInPoint) {
                    Image(systemName: "curlybraces")
                }
                .help("Set In point")

                Button(action: onSetOutPoint) {
                    Image(systemName: "curlybraces.square.fill")
                }
                .help("Set Out point")

                Spacer()

                Button { isPIP.toggle() } label: {
                    Image(systemName: isPIP ? "pip.fill" : "pip")
                        .foregroundStyle(isPIP ? Color.yellow : Color.primary)
                }
                .help("Picture in Picture")

                Button(action: onSnapshot) {
                    Image(systemName: "camera")
                }
                .help("Snapshot frame")

                Button(action: onFullscreen) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .help("Fullscreen")
            }
            .buttonStyle(.borderless)
            .font(.system(size: 13))
            .foregroundStyle(Color.white.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
    }

    private func formatTimecode(_ seconds: Double) -> String {
        let total = max(0, seconds)
        let hours = Int(total) / 3600
        let minutes = Int(total) % 3600 / 60
        let secs = Int(total) % 60
        let frames = Int((total.truncatingRemainder(dividingBy: 1)) * 100)
        if hours > 0 {
            return String(format: "%d:%02d:%02d:%02d", hours, minutes, secs, frames)
        }
        return String(format: "%02d:%02d:%02d", minutes, secs, frames)
    }
}
