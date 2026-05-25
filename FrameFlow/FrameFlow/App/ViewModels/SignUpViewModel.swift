//
//  SignUpViewModel.swift
//  FrameFlow
//

import Foundation
import Supabase

enum SignUpOutcome {
    case signedIn(User)
    case emailConfirmationRequired
    case failed
}

@Observable
final class SignUpViewModel {
    var name = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?

    func validate() -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            return "Enter your full name."
        }
        if trimmedEmail.isEmpty {
            return "Enter your email address."
        }
        if !trimmedEmail.contains("@") {
            return "Enter a valid email address."
        }
        if password.count < 8 {
            return "Password must be at least 8 characters."
        }
        if password != confirmPassword {
            return "Passwords do not match."
        }
        return nil
    }

    func signUp() async -> SignUpOutcome {
        errorMessage = nil
        successMessage = nil

        if let validationError = validate() {
            errorMessage = validationError
            return .failed
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await AuthService.shared.signUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            return .signedIn(user)
        } catch AuthServiceError.emailConfirmationRequired {
            successMessage = AuthServiceError.emailConfirmationRequired.errorDescription
            return .emailConfirmationRequired
        } catch {
            errorMessage = userFacingMessage(for: error)
            return .failed
        }
    }

    private func userFacingMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
