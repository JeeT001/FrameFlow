//
//  ExpiryBannerView.swift
//  FrameFlow
//

import SwiftUI

struct ExpiryBannerView: View {
    let status: SubscriptionStatus
    let onRenew: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColors.proGold)

            Text(message)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button("Renew") {
                onRenew()
            }
            .buttonStyle(.borderedProminent)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Dismiss until next launch")
        }
        .padding(14)
        .background(AppColors.proGold.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var message: String {
        switch status {
        case .past_due:
            "Your payment is past due. Update billing to keep Pro features."
        case .expired:
            "Your Pro plan has ended. Renew to restore access."
        default:
            ""
        }
    }
}

#Preview("Expired") {
    ExpiryBannerView(
        status: .expired,
        onRenew: {},
        onDismiss: {}
    )
    .padding()
}

#Preview("Past due") {
    ExpiryBannerView(
        status: .past_due,
        onRenew: {},
        onDismiss: {}
    )
    .padding()
}
