//
//  LoginViewModel.swift
//  FrameFlow
//

import Foundation

@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?

    func validate() -> String? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty {
            return "Enter your email address."
        }
        if !trimmedEmail.contains("@") {
            return "Enter a valid email address."
        }
        if password.isEmpty {
            return "Enter your password."
        }
        return nil
    }

    @discardableResult
    func logIn() async -> Bool {
        errorMessage = nil

        if let validationError = validate() {
            errorMessage = validationError
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await AuthService.shared.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            return true
        } catch {
            errorMessage = userFacingMessage(for: error)
            return false
        }
    }

    private func userFacingMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
