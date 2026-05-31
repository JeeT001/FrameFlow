//
//  ResetPasswordViewModel.swift
//  FrameFlow
//

import Foundation

@Observable
final class ResetPasswordViewModel {
    var password = ""
    var confirmPassword = ""
    var isLoading = false
    var errorMessage: String?

    func validate() -> String? {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.count < 8 {
            return "Password must be at least 8 characters."
        }
        if trimmed != confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines) {
            return "Passwords do not match."
        }
        return nil
    }

    @discardableResult
    func updatePassword(appState: AppState, router: AppRouter) async -> Bool {
        errorMessage = nil

        if let validationError = validate() {
            errorMessage = validationError
            return false
        }

        isLoading = true
        defer { isLoading = false }

        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await AuthService.shared.updatePassword(trimmed)
            try await AuthService.shared.signOut()
            appState.finishPasswordRecovery(
                successMessage: "Your password was updated. Log in with your new password."
            )
            router.navigate(to: .login)
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
