//
//  DashboardFeedbackBanner.swift
//  FrameFlow
//

import SwiftUI

struct DashboardFeedbackBanner: View {
    let onShareFeedback: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.title3)
                .foregroundStyle(AppColors.primary)

            Button(action: onShareFeedback) {
                HStack(spacing: 0) {
                    Text("Enjoying \(AppBranding.name)? Share your feedback")
                    Text(" →")
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.primary)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(AppColors.border.opacity(0.35), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Dismiss for now")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColors.border.opacity(0.6))
        }
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}

#Preview {
    DashboardFeedbackBanner(onShareFeedback: {}, onDismiss: {})
        .padding()
}
