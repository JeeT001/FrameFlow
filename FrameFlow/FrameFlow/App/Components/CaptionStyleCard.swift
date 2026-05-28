//
//  CaptionStyleCard.swift
//  FrameFlow
//

import SwiftUI

struct CaptionStyleCard: View {
    let preset: CaptionStylePreset
    let isSelected: Bool
    let onSelect: () -> Void

    private var previewStyle: CaptionStyleConfig {
        CaptionStyleConfig.config(for: preset, position: .bottom)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.85))
                        .frame(width: 120, height: 64)

                    CaptionStyleMiniPreview(style: previewStyle)
                }

                Text(previewStyle.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CaptionStyleMiniPreview: View {
    let style: CaptionStyleConfig

    var body: some View {
        Group {
            switch style.preset {
            case .tiktokBold:
                Text("BOLD")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Color.yellow)
            case .highlightedWord:
                Text("word")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 6)
                    .background(Color.white.opacity(0.2), in: Capsule())
            case .minimal:
                Text("Aa")
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
            case .custom:
                Text("Custom")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            default:
                Text("Caption")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}
