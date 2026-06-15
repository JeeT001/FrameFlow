//
//  AuthLegalConsentFooter.swift
//  FrameFlow
//

import SwiftUI

struct AuthLegalConsentFooter: View {
    @Environment(AppRouter.self) private var router

    let returnRoute: AppRoute

    var body: some View {
        VStack(spacing: 6) {
            Text("By creating an account, you agree to our")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: 4) {
                Button("Terms of Service") {
                    router.navigateToLegal(.termsOfService, returningTo: returnRoute)
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.primary)

                Text("and")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Button("Privacy Policy") {
                    router.navigateToLegal(.privacyPolicy, returningTo: returnRoute)
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.primary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}

#Preview {
    AuthLegalConsentFooter(returnRoute: .signUp)
        .environment(AppRouter())
        .padding()
}
