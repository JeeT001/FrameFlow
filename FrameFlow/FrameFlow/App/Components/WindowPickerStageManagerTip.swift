//
//  WindowPickerStageManagerTip.swift
//  FrameFlow
//

import SwiftUI

struct WindowPickerStageManagerTip: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "macwindow.on.rectangle.rtl")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.primary)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 12) {
                tipSection(
                    title: "Stage Manager tip",
                    body: "Windows in Stage Manager’s left shelf may look blurred here. " +
                        "Click a window into the main area first, then tap Refresh."
                )

                tipSection(
                    title: "Selection order",
                    body: "Windows stack in the order you pick them: the first window sits at the back, " +
                        "each new one goes on top of the last, and the fourth window is in front of the others. " +
                        "If the webcam is on, it appears on top of every window."
                )
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(AppColors.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppColors.primary.opacity(0.18))
        )
    }

    private func tipSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text(body)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    WindowPickerStageManagerTip()
        .padding()
        .frame(width: 520)
}
