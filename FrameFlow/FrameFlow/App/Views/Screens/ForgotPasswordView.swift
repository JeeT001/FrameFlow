//
//  ForgotPasswordView.swift
//  FrameFlow
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = ForgotPasswordViewModel()

    private var fieldsDisabled: Bool {
        viewModel.isLoading || viewModel.successMessage != nil
    }

    var body: some View {
        AuthScreenChrome(
            hero: .systemImage("lock.circle"),
            title: "Reset your password",
            subtitle: "Enter your email and we'll send you a reset link to get back into your account."
        ) {
            AuthTextField(
                label: "Email",
                icon: "envelope",
                text: $viewModel.email,
                isDisabled: fieldsDisabled
            )
            .textContentType(.emailAddress)

            if let errorMessage = viewModel.errorMessage {
                AuthErrorBanner(message: errorMessage)
            }

            if let successMessage = viewModel.successMessage {
                AuthSuccessBanner(message: successMessage)
            }

            AuthPrimaryButton(
                title: "Send Reset Link",
                isLoading: viewModel.isLoading,
                isDisabled: fieldsDisabled
            ) {
                Task {
                    await viewModel.sendResetLink()
                }
            }
        } footer: {
            AuthFooterLink(title: "Back to Log In", icon: "arrow.left") {
                router.navigate(to: .login)
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environment(AppRouter())
}
