//
//  ProfileViewModel.swift
//  FrameFlow
//

import Foundation
import Supabase

@Observable
final class ProfileViewModel {
    var displayName = ""
    var isSaving = false
    var isSendingPasswordReset = false
    var alertTitle = ""
    var alertMessage = ""
    var showAlert = false

    func syncDisplayName(from user: User?) {
        displayName = UserDisplayHelpers.displayName(for: user)
    }

    func saveDisplayName(appState: AppState) async {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            presentAlert(title: "Invalid Name", message: "Display name cannot be empty.")
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let updatedUser = try await UserService.shared.updateDisplayName(trimmed)
            appState.currentUser = updatedUser
            displayName = UserDisplayHelpers.displayName(for: updatedUser)
            presentAlert(title: "Saved", message: "Your display name was updated.")
        } catch let error as AuthServiceError {
            presentAlert(title: "Save Failed", message: error.localizedDescription)
        } catch {
            presentAlert(title: "Save Failed", message: error.localizedDescription)
        }
    }

    func sendPasswordReset(email: String?) async {
        guard let email, !email.isEmpty else {
            presentAlert(title: "No Email", message: "No email address is available for this account.")
            return
        }

        isSendingPasswordReset = true
        defer { isSendingPasswordReset = false }

        do {
            try await AuthService.shared.resetPassword(email: email)
            presentAlert(
                title: "Email Sent",
                message: "Check your inbox for a link to reset your password."
            )
        } catch let error as AuthServiceError {
            presentAlert(title: "Request Failed", message: error.localizedDescription)
        } catch {
            presentAlert(title: "Request Failed", message: error.localizedDescription)
        }
    }

    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
