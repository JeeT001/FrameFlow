//
//  ResetPasswordView.swift
//  FrameFlow
//

import SwiftUI

struct ResetPasswordView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = ResetPasswordViewModel()

    var body: some View {
        AuthScreenChrome(
            hero: .systemImage("checkmark.shield"),
            title: "Set a new password",
            subtitle: "Choose a strong password to keep your \(AppBranding.name) account secure."
        ) {
            AuthTextField(
                label: "New password",
                icon: "lock",
                text: $viewModel.password,
                placeholder: "Enter new password",
                isSecure: true,
                isDisabled: viewModel.isLoading
            )
            .textContentType(.newPassword)

            AuthTextField(
                label: "Confirm password",
                icon: "lock",
                text: $viewModel.confirmPassword,
                placeholder: "Confirm new password",
                isSecure: true,
                isDisabled: viewModel.isLoading
            )
            .textContentType(.newPassword)

            if let errorMessage = viewModel.errorMessage {
                AuthErrorBanner(message: errorMessage)
            }

            AuthPrimaryButton(
                title: "Update Password",
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.isLoading
            ) {
                Task {
                    AuthFocus.dismiss()
                    if await viewModel.updatePassword(appState: appState, router: router) {
                        AuthFocus.dismiss()
                    }
                }
            }
        } footer: {
            AuthFooterLink(title: "Back to Log In", icon: "arrow.left") {
                router.navigate(to: .login)
            }
        }
        .onDisappear {
            AuthFocus.dismiss()
        }
    }
}

#Preview {
    ResetPasswordView()
        .environment(AppState())
        .environment(AppRouter())
}
