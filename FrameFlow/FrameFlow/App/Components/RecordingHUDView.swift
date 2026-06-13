//
//  RecordingHUDView.swift
//  FrameFlow
//

import SwiftUI

struct RecordingHUDView: View {
    let isPaused: Bool
    let isRecording: Bool
    let formattedDuration: String
    let zoomLabel: String
    let audioMode: AudioModeOption
    let onPauseResume: () -> Void
    let onStop: () -> Void
    let isPauseEnabled: Bool
    let isStopEnabled: Bool

    var body: some View {
        HStack(spacing: 16) {
            leftSection
            Spacer(minLength: 8)
            centerSection
            Spacer(minLength: 8)
            rightSection
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background {
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.65))
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.12))
        }
        .shadow(color: .black.opacity(0.45), radius: 10, y: 4)
    }

    private var leftSection: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isPaused ? AppColors.pauseYellow : AppColors.recRed)
                .frame(width: 10, height: 10)
            Text(formattedDuration)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
    }

    private var centerSection: some View {
        HStack(spacing: 14) {
            Label(zoomLabel, systemImage: "viewfinder")
                .labelStyle(.titleAndIcon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.92))

            Image(systemName: audioMode.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
                .help(audioMode.title)
        }
    }

    private var rightSection: some View {
        HStack(spacing: 8) {
            Button(isPaused ? "Resume" : "Pause") {
                onPauseResume()
            }
            .buttonStyle(.bordered)
            .tint(.white)
            .disabled(!isPauseEnabled)

            Button("Stop") {
                onStop()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(!isStopEnabled)
        }
    }
}

#Preview {
    RecordingHUDView(
        isPaused: false,
        isRecording: true,
        formattedDuration: "00:42",
        zoomLabel: "1.5x",
        audioMode: .mic,
        onPauseResume: {},
        onStop: {},
        isPauseEnabled: true,
        isStopEnabled: true
    )
    .padding()
    .frame(width: 720)
    .background(Color.gray.opacity(0.3))
}
