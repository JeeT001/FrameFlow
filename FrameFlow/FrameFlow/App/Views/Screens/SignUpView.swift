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
        AuthFormLayout(
            title: "Sign Up",
            subtitle: "Create your FrameFlow account to save recordings and settings."
        ) {
            TextField("Full name", text: $viewModel.name)
                .textFieldStyle(.roundedBorder)
                .textContentType(.name)
                .disabled(viewModel.isLoading)

            TextField("Email", text: $viewModel.email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .disabled(viewModel.isLoading)

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.newPassword)
                .disabled(viewModel.isLoading)

            SecureField("Confirm password", text: $viewModel.confirmPassword)
                .textFieldStyle(.roundedBorder)
                .textContentType(.newPassword)
                .disabled(viewModel.isLoading)

            if let errorMessage = viewModel.errorMessage {
                AuthErrorBanner(message: errorMessage)
            }

            if let successMessage = viewModel.successMessage {
                AuthSuccessBanner(message: successMessage)
            }

            Button {
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
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isLoading)
        } footer: {
            Button("Already have an account? Log In") {
                router.navigate(to: .login)
            }
            .buttonStyle(.link)
            .font(.callout)
            .frame(maxWidth: 380)
        }
    }
}

#Preview {
    SignUpView()
        .environment(AppState())
        .environment(AppRouter())
}
