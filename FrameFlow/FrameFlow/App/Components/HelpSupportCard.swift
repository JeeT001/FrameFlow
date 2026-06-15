//
//  HelpSupportCard.swift
//  FrameFlow
//

import SwiftUI

struct HelpSupportCard: View {
    let onEmailSupport: () -> Void
    let version: String
    let onPrivacy: () -> Void
    let onTerms: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "lifepreserver")
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.primary.opacity(0.1), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Need more help?")
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Our team can help with permissions, exports, and account questions.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button(action: onEmailSupport) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                    Text("Email Support")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Divider()

            HStack {
                Text("App version")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text(version)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
            }

            HStack(spacing: 20) {
                Button("Privacy Policy", action: onPrivacy)
                    .buttonStyle(.plain)
                    .font(.callout)
                    .foregroundStyle(AppColors.primary)

                Button("Terms of Service", action: onTerms)
                    .buttonStyle(.plain)
                    .font(.callout)
                    .foregroundStyle(AppColors.primary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColors.border.opacity(0.7))
        }
    }
}
