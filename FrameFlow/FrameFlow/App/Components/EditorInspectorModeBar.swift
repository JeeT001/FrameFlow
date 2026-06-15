//
//  EditorInspectorModeBar.swift
//  FrameFlow
//

import SwiftUI

struct EditorInspectorModeBar: View {
    @Binding var mode: EditorInspectorMode
    let isPro: Bool
    let onCaptionsLockedTap: () -> Void
    let onModeChange: (EditorInspectorMode) -> Void

    var body: some View {
        HStack(spacing: 4) {
            modePill(
                title: "Edit",
                icon: nil,
                isSelected: mode == .edit,
                isLocked: false
            ) {
                mode = .edit
                onModeChange(.edit)
            }

            modePill(
                title: "Captions",
                icon: isPro ? nil : "lock.fill",
                isSelected: mode == .captions,
                isLocked: !isPro
            ) {
                if isPro {
                    mode = .captions
                    onModeChange(.captions)
                } else {
                    onCaptionsLockedTap()
                }
            }
            .help(isPro ? "Caption styles and segments" : "Auto captions require \(AppBranding.proName) — click to learn more")
        }
        .padding(4)
        .background(AppColors.border.opacity(0.25), in: Capsule())
    }

    private func modePill(
        title: String,
        icon: String?,
        isSelected: Bool,
        isLocked: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2.weight(.semibold))
                }
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? Color.white : AppColors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(isLocked ? AppColors.proGold : AppColors.primary)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
