//
//  LoginViewModel.swift
//  FrameFlow
//

import Foundation
import Supabase

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
    func logIn() async -> User? {
        errorMessage = nil

        if let validationError = validate() {
            errorMessage = validationError
            return nil
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await AuthService.shared.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            await UserService.shared.ensureUserProfile(for: user)
            return user
        } catch {
            errorMessage = userFacingMessage(for: error)
            return nil
        }
    }

    private func userFacingMessage(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
