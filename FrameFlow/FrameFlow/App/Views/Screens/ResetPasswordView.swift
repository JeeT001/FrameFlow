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
        AuthFormLayout(
            title: "Set New Password",
            subtitle: "Choose a new password for your FrameFlow account."
        ) {
            SecureField("New Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.newPassword)
                .disabled(viewModel.isLoading)

            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                .textFieldStyle(.roundedBorder)
                .textContentType(.newPassword)
                .disabled(viewModel.isLoading)

            if let errorMessage = viewModel.errorMessage {
                AuthErrorBanner(message: errorMessage)
            }

            Button {
                Task {
                    await viewModel.updatePassword(appState: appState, router: router)
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Update Password")
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
    ResetPasswordView()
        .environment(AppState())
        .environment(AppRouter())
}
