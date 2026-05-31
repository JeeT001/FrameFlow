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
    /// Staged recording between Stop and Export/Discard (not yet in RecordingStore).
    var pendingRecording: RecordingMetadata?
    /// Recording queued for the Export screen (pending or Dashboard re-export).
    var exportRecordingID: UUID?
    /// Recording shown on the Recording Detail screen.
    var detailRecordingID: UUID?
    /// Synced profile from `public.users` (subscription row logged in DEBUG only).
    var syncedProfile: FrameFlowUser?

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
        pendingRecording = nil
        exportRecordingID = nil
        detailRecordingID = nil
    }

    /// User-specific prefs cleared on delete; device settings and onboarding flag are kept.
    private func clearUserSpecificDefaults() {
        SettingsStore.shared.expiryBannerDismissed = false
    }
}
