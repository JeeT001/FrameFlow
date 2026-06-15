//
//  DashboardHeroBanner.swift
//  FrameFlow
//

import SwiftUI

struct DashboardHeroBanner: View {
    let onNewRecording: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Start recording something amazing.")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Record multiple windows, add your camera, generate captions, and export in one click.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)

            Text("Format and layout — choose on the next screens.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))

            Button(action: onNewRecording) {
                HStack(spacing: 8) {
                    Image(systemName: "record.circle")
                    Text("New Recording")
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(AppColors.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.white, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(28)
        .background {
            heroGradient
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.12))
        }
    }

    private var heroGradient: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppColors.primary,
                    AppColors.primary.opacity(0.82),
                    AppColors.primary.opacity(0.65),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 220, height: 220)
                .offset(x: 120, y: -40)

            Circle()
                .fill(.white.opacity(0.05))
                .frame(width: 160, height: 160)
                .offset(x: -80, y: 60)
        }
    }
}
