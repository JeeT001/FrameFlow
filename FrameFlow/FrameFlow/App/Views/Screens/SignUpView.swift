//
//  SignUpView.swift
//  FrameFlow
//

import SwiftUI

struct SignUpView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var viewModel = SignUpViewModel()

    var body: some View {
        AuthScreenChrome(
            hero: .brandWordmark,
            title: "Create your account",
            subtitle: "Create your \(AppBranding.name) account to save recordings and settings."
        ) {
            AuthTextField(
                label: "Full name",
                icon: "person",
                text: $viewModel.name,
                isDisabled: viewModel.isLoading
            )
            .textContentType(.name)

            AuthTextField(
                label: "Email",
                icon: "envelope",
                text: $viewModel.email,
                isDisabled: viewModel.isLoading
            )
            .textContentType(.emailAddress)

            AuthTextField(
                label: "Password",
                icon: "lock",
                text: $viewModel.password,
                isSecure: true,
                isDisabled: viewModel.isLoading
            )
            .textContentType(.newPassword)

            AuthTextField(
                label: "Confirm password",
                icon: "lock",
                text: $viewModel.confirmPassword,
                isSecure: true,
                isDisabled: viewModel.isLoading
            )
            .textContentType(.newPassword)

            if let errorMessage = viewModel.errorMessage {
                AuthErrorBanner(message: errorMessage)
            }

            if let successMessage = viewModel.successMessage {
                AuthSuccessBanner(message: successMessage)
            }

            AuthPrimaryButton(
                title: "Sign Up",
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.isLoading
            ) {
                Task {
                    let outcome = await viewModel.signUp()
                    switch outcome {
                    case .signedIn(let user):
                        await appState.markAuthenticated(user: user)
                        router.selectSidebar(.home)
                    case .emailConfirmationRequired, .failed:
                        break
                    }
                }
            }
        } footer: {
            VStack(spacing: 12) {
                AuthLegalConsentFooter(returnRoute: .signUp)

                AuthFooterLink(title: "Already have an account? Log In") {
                    router.navigate(to: .login)
                }
            }
        }
    }
}

#Preview {
    SignUpView()
        .environment(AppState())
        .environment(AppRouter())
}
