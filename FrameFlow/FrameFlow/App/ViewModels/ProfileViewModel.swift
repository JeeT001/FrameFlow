//
//  ProfileViewModel.swift
//  FrameFlow
//

import Foundation
import Supabase

@Observable
final class ProfileViewModel {
    var displayName = ""
    private(set) var savedDisplayName = ""
    var isSaving = false
    var showSaveSuccess = false
    var isSendingPasswordReset = false
    var showDeleteConfirmation = false
    var isDeletingAccount = false
    var alertTitle = ""
    var alertMessage = ""
    var showAlert = false

    static var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        guard let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return version
        }
        return build == version ? version : "\(version) (\(build))"
    }

    var canSaveDisplayName: Bool {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed != savedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func syncDisplayName(from user: User?) {
        let name = UserDisplayHelpers.displayName(for: user)
        displayName = name
        savedDisplayName = name
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
            let name = UserDisplayHelpers.displayName(for: updatedUser)
            displayName = name
            savedDisplayName = name
            await playSaveSuccessAnimation()
        } catch let error as AuthServiceError {
            presentAlert(title: "Save Failed", message: error.localizedDescription)
        } catch {
            presentAlert(title: "Save Failed", message: error.localizedDescription)
        }
    }

    func deleteAccount(appState: AppState, router: AppRouter) async {
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            try await appState.deleteAccount()
            router.navigate(to: .login)
        } catch let error as AuthServiceError {
            presentAlert(title: "Delete Failed", message: error.localizedDescription)
        } catch {
            presentAlert(title: "Delete Failed", message: error.localizedDescription)
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

    private func playSaveSuccessAnimation() async {
        showSaveSuccess = true
        try? await Task.sleep(for: .seconds(1))
        showSaveSuccess = false
    }

    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
