//
//  LoginView.swift
//  FrameFlow
//

import SwiftUI

struct LoginView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = LoginViewModel()

    var body: some View {
        AuthFormLayout(
            title: "Log In",
            subtitle: "Sign in with your FrameFlow account."
        ) {
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.username)
                .disabled(viewModel.isLoading)

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .disabled(viewModel.isLoading)

            if let errorMessage = viewModel.errorMessage {
                AuthErrorBanner(message: errorMessage)
            }

            Button {
                Task {
                    let success = await viewModel.logIn()
                    if success {
                        router.navigate(to: .dashboard)
                    }
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isLoading)
        } footer: {
            HStack(spacing: 16) {
                Button("Forgot Password?") {
                    router.navigate(to: .forgotPassword)
                }
                .buttonStyle(.link)

                Button("Sign Up") {
                    router.navigate(to: .signUp)
                }
                .buttonStyle(.link)
            }
            .font(.callout)
            .frame(maxWidth: 380)
        }
    }
}

#Preview {
    LoginView()
        .environment(AppRouter())
}
