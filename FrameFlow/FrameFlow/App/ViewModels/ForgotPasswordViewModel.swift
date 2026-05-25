//
//  ForgotPasswordViewModel.swift
//  FrameFlow
//

import Foundation

@Observable
final class ForgotPasswordViewModel {
    var email = ""
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?

    func validate() -> String? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty {
            return "Enter your email address."
        }
        if !trimmedEmail.contains("@") {
            return "Enter a valid email address."
        }
        return nil
    }

    @discardableResult
    func sendResetLink() async -> Bool {
        errorMessage = nil
        successMessage = nil

        if let validationError = validate() {
            errorMessage = validationError
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthService.shared.resetPassword(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            successMessage = "If an account exists for this email, a reset link has been sent."
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
