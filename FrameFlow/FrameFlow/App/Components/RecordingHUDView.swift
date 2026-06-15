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
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppColors.background.opacity(0.96))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColors.border.opacity(0.6))
        }
        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
    }

    private var leftSection: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isPaused ? AppColors.pauseYellow : AppColors.recRed)
                .frame(width: 10, height: 10)

            Text(formattedDuration)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    private var centerSection: some View {
        HStack(spacing: 16) {
            Label(zoomLabel, systemImage: "viewfinder")
                .labelStyle(.titleAndIcon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppColors.textSecondary)

            Image(systemName: audioMode.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .help(audioMode.title)
        }
    }

    private var rightSection: some View {
        HStack(spacing: 10) {
            Button {
                onPauseResume()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    Text(isPaused ? "Resume" : "Pause")
                }
            }
            .buttonStyle(.bordered)
            .disabled(!isPauseEnabled)

            Button {
                onStop()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                    Text("Stop")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.recRed)
            .disabled(!isStopEnabled)
        }
    }
}

#Preview {
    RecordingHUDView(
        isPaused: false,
        isRecording: true,
        formattedDuration: "00:42",
        zoomLabel: "1.0x",
        audioMode: .combined,
        onPauseResume: {},
        onStop: {},
        isPauseEnabled: true,
        isStopEnabled: true
    )
    .padding()
    .frame(width: 720)
    .background(Color.black)
}
