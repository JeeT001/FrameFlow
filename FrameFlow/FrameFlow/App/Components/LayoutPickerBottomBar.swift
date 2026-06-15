//
//  LayoutPickerBottomBar.swift
//  FrameFlow
//

import SwiftUI

struct LayoutPickerBottomBar: View {
    let windowCount: Int
    let windowLabels: [String]
    let startDisabled: Bool
    let onAddWindows: () -> Void
    let onStartRecording: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(windowCount) window(s) selected")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                HStack(spacing: 8) {
                    ForEach(Array(windowLabels.prefix(4).enumerated()), id: \.offset) { _, label in
                        windowChip(label)
                    }

                    Button(action: onAddWindows) {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 32, height: 32)
                            .background(AppColors.primary.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Add or change windows")
                }
            }

            Spacer()

            Button(action: onStartRecording) {
                HStack(spacing: 8) {
                    Image(systemName: "record.circle")
                    Text("Start Recording")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(startDisabled)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(AppColors.background)
    }

    private func windowChip(_ label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "macwindow")
                .font(.caption2)
                .foregroundStyle(AppColors.primary)
            Text(chipTitle(from: label))
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppColors.surface, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(AppColors.border)
        }
    }

    private func chipTitle(from label: String) -> String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Window" }
        if trimmed.count > 18 {
            return String(trimmed.prefix(16)) + "…"
        }
        return trimmed
    }
}
