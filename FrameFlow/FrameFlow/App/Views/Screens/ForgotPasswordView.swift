//
//  ForgotPasswordView.swift
//  FrameFlow
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = ForgotPasswordViewModel()

    var body: some View {
        AuthFormLayout(
            title: "Forgot Password",
            subtitle: "Enter your email and we will send you a reset link."
        ) {
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .disabled(viewModel.isLoading)

            if let errorMessage = viewModel.errorMessage {
                AuthErrorBanner(message: errorMessage)
            }

            if let successMessage = viewModel.successMessage {
                AuthSuccessBanner(message: successMessage)
            }

            Button {
                Task {
                    await viewModel.sendResetLink()
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Send Reset Link")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isLoading)
        } footer: {
            Button("Back to Log In") {
                router.navigate(to: .login)
            }
            .buttonStyle(.link)
            .font(.callout)
            .frame(maxWidth: 380)
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environment(AppRouter())
}
