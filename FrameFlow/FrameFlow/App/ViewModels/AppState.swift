//
//  AppState.swift
//  FrameFlow
//

import CoreGraphics
import Foundation
import Supabase

enum AuthStatus {
    case firstLaunch
    case unauthenticated
    case authenticated
}

enum SubscriptionStatus {
    case free
    case active
    case past_due
    case expired
}

@Observable
final class AppState {
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    var authStatus: AuthStatus = .unauthenticated
    var currentUser: User?
    var isBootstrapping = true
    var subscriptionStatus: SubscriptionStatus = .free
    var selectedWindowIDs: Set<CGWindowID> = []
    var selectedFormat: RecordingFormat = .sixteenByNine
    var selectedLayoutPreset: LayoutPreset = .stacked
    var windowPlacements: [CGWindowID: WindowPlacement] = [:]
    /// Staged recording between Stop and Export/Discard (not yet in RecordingStore).
    var pendingRecording: RecordingMetadata?
    /// Recording queued for the Export screen (pending or Dashboard re-export).
    var exportRecordingID: UUID?
    /// Recording shown on the Recording Detail screen.
    var detailRecordingID: UUID?
    /// Synced profile from `public.users` (subscription row logged in DEBUG only).
    var syncedProfile: FrameFlowUser?
    /// Deep-link password recovery — session exists in Supabase client but UI stays on auth stack.
    var isPasswordRecoveryFlow = false
    /// Shown once on Login after a successful password reset.
    var pendingLoginMessage: String?
    /// Auth callback URL received before bootstrap completes (cold start from email link).
    var pendingAuthCallbackURL: URL?

    var isPro: Bool {
        subscriptionStatus == .active
    }

    func syncSubscriptionAfterAuth(userId: UUID) async {
        let manager = SubscriptionManager.shared
        await manager.logIn(appUserID: userId.uuidString)
        await manager.fetchStatus()
        manager.syncToAppState(self)
    }

    func bootstrap(router: AppRouter) async {
        isBootstrapping = true
        defer { isBootstrapping = false }

        guard UserDefaults.standard.bool(forKey: Self.hasCompletedOnboardingKey) else {
            authStatus = .firstLaunch
            return
        }

        if let url = pendingAuthCallbackURL {
            pendingAuthCallbackURL = nil
            await processAuthCallbackURL(url, router: router)
            return
        }

        if isPasswordRecoveryFlow {
            authStatus = .unauthenticated
            router.navigate(to: .resetPassword)
            return
        }

        if let session = await AuthService.shared.restoreSession() {
            currentUser = session.user
            authStatus = .authenticated
            AnalyticsService.identify(userID: session.user.id.uuidString)
            await UserService.shared.ensureUserProfile(for: session.user)
            syncedProfile = try? await UserService.shared.fetchUser(userId: session.user.id)
            await syncSubscriptionAfterAuth(userId: session.user.id)
            #if DEBUG
            await UserService.shared.debugLogSubscription(for: session.user.id)
            #endif
            router.selectSidebar(.home)
            return
        }

        currentUser = nil
        authStatus = .unauthenticated
        router.navigate(to: .login)
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.hasCompletedOnboardingKey)

        if let session = AuthService.shared.getCurrentSession(), !session.isExpired {
            currentUser = session.user
            authStatus = .authenticated
        } else {
            currentUser = nil
            authStatus = .unauthenticated
        }
    }

    func markAuthenticated(user: User) async {
        currentUser = user
        authStatus = .authenticated
        AnalyticsService.identify(userID: user.id.uuidString)
        await syncSubscriptionAfterAuth(userId: user.id)
    }

    func queueAuthCallbackURL(_ url: URL) {
        pendingAuthCallbackURL = url
    }

    func processAuthCallbackIfNeeded(router: AppRouter) async {
        guard let url = pendingAuthCallbackURL else { return }
        pendingAuthCallbackURL = nil
        await processAuthCallbackURL(url, router: router)
    }

    func processAuthCallbackURL(_ url: URL, router: AppRouter) async {
        guard url.scheme == AuthConstants.callbackScheme else { return }
        guard SupabaseClientProvider.isConfigured else { return }

        do {
            _ = try await AuthService.shared.session(from: url)
            isPasswordRecoveryFlow = true
            authStatus = .unauthenticated
            currentUser = nil
            router.navigate(to: .resetPassword)
        } catch {
            #if DEBUG
            print("[AppState] auth callback failed: \(error.localizedDescription)")
            #endif
        }
    }

    func finishPasswordRecovery(successMessage: String) {
        isPasswordRecoveryFlow = false
        pendingLoginMessage = successMessage
        clearAuthenticatedSession()
    }

    func consumePendingLoginMessage() -> String? {
        defer { pendingLoginMessage = nil }
        return pendingLoginMessage
    }

    func signOut() async {
        do {
            try await AuthService.shared.signOut()
        } catch {
            // Clear local auth state even if the network sign-out fails.
        }
        clearAuthenticatedSession()
        await SubscriptionManager.shared.logOut()
    }

    /// Deletes the remote auth account, clears RevenueCat + local session, resets user-specific prefs.
    func deleteAccount() async throws {
        try await AuthService.shared.deleteAccount()
        await SubscriptionManager.shared.logOut()
        try? await AuthService.shared.signOut()
        clearAuthenticatedSession()
        clearUserSpecificDefaults()
    }

    private func clearAuthenticatedSession() {
        AnalyticsService.reset()
        currentUser = nil
        authStatus = .unauthenticated
        subscriptionStatus = .free
        syncedProfile = nil
        isPasswordRecoveryFlow = false
        pendingRecording = nil
        exportRecordingID = nil
        detailRecordingID = nil
    }

    /// User-specific prefs cleared on delete; device settings and onboarding flag are kept.
    private func clearUserSpecificDefaults() {
        SettingsStore.shared.expiryBannerDismissed = false
    }
}
