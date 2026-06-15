//
//  LoginView.swift
//  FrameFlow
//

import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = LoginViewModel()
    @State private var successMessage: String?

    var body: some View {
        AuthScreenChrome(
            hero: .brandWordmark,
            title: "Welcome back",
            subtitle: "Sign in with your \(AppBranding.name) account."
        ) {
            AuthTextField(
                label: "Email",
                icon: "envelope",
                text: $viewModel.email,
                isDisabled: viewModel.isLoading
            )
            .textContentType(.username)

            AuthTextField(
                label: "Password",
                icon: "lock",
                text: $viewModel.password,
                isSecure: true,
                isDisabled: viewModel.isLoading
            )
            .textContentType(.password)

            if let errorMessage = viewModel.errorMessage {
                AuthErrorBanner(message: errorMessage)
            }

            if let successMessage {
                AuthSuccessBanner(message: successMessage)
            }

            AuthPrimaryButton(
                title: "Log In",
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.isLoading
            ) {
                Task {
                    if let user = await viewModel.logIn() {
                        await appState.markAuthenticated(user: user)
                        router.selectSidebar(.home)
                    }
                }
            }
        } footer: {
            HStack(spacing: 20) {
                AuthFooterLink(title: "Forgot Password?") {
                    router.navigate(to: .forgotPassword)
                }

                AuthFooterLink(title: "Sign Up") {
                    router.navigate(to: .signUp)
                }
            }
        }
        .onAppear {
            if let message = appState.consumePendingLoginMessage() {
                successMessage = message
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AppState())
        .environment(AppRouter())
}
