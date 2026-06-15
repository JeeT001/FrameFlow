//
//  RecordingLayoutMiniPreview.swift
//  FrameFlow
//

import SwiftUI

struct RecordingLayoutMiniPreview: View {
    let activePreset: LayoutPreset

    var body: some View {
        HStack(spacing: 6) {
            ForEach(LayoutPreset.allCases) { preset in
                VStack(spacing: 2) {
                    LayoutPresetDiagram(preset: preset)
                        .frame(width: 36, height: 24)
                        .opacity(preset == activePreset ? 1 : 0.45)

                    if preset == activePreset {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 4, height: 4)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(4)
                .background(
                    preset == activePreset
                        ? AppColors.primary.opacity(0.1)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                )
                .overlay {
                    if preset == activePreset {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(AppColors.primary.opacity(0.35), lineWidth: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(AppColors.background.opacity(0.95), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppColors.border.opacity(0.8))
        }
    }
}
