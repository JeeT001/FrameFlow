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
    /// In-memory caption handoff when navigating to Export (sidecar may be unavailable on installed builds).
    var stagedExportCaptionRecordingID: UUID?
    var stagedExportCaptionSegments: [CaptionSegment]?
    var stagedExportCaptionLeadingGap: Double?
    var stagedExportCaptionStyle: CaptionStyleConfig?
    /// Recording shown on the Recording Detail screen.
    var detailRecordingID: UUID?
    /// Synced profile from `public.users` (subscription row logged in DEBUG only).
    var syncedProfile: FrameFlowUser?
    /// Deep-link password recovery — session exists in Supabase client but UI stays on auth stack.
    var isPasswordRecoveryFlow = false
    /// Shown once on Login after a successful password reset.
    var pendingLoginMessage: String?
    /// Deep link received before bootstrap completes (cold start).
    var pendingIncomingURL: URL?
    /// Shown once after browser checkout deep link activates Pro.
    var pendingSubscriptionSuccessMessage: String?

    var isPro: Bool {
        subscriptionStatus == .active
    }

    /// Stage caption data before navigating to `.export` (ExportView does not share Editor's view model).
    func stageExportCaptions(
        recordingID: UUID,
        segments: [CaptionSegment],
        leadingGap: Double = 0,
        style: CaptionStyleConfig? = nil
    ) {
        guard !segments.isEmpty else {
            clearStagedExportCaptions()
            return
        }
        stagedExportCaptionRecordingID = recordingID
        stagedExportCaptionSegments = segments
        stagedExportCaptionLeadingGap = leadingGap > 0.001 ? leadingGap : nil
        stagedExportCaptionStyle = style
    }

    /// One-shot read of staged captions for the Export screen.
    func consumeStagedExportCaptions(for recordingID: UUID) -> (
        segments: [CaptionSegment],
        leadingGap: Double?,
        style: CaptionStyleConfig?
    )? {
        guard stagedExportCaptionRecordingID == recordingID,
              let segments = stagedExportCaptionSegments,
              !segments.isEmpty else {
            return nil
        }
        let leadingGap = stagedExportCaptionLeadingGap
        let style = stagedExportCaptionStyle
        clearStagedExportCaptions()
        return (segments, leadingGap, style)
    }

    func clearStagedExportCaptions() {
        stagedExportCaptionRecordingID = nil
        stagedExportCaptionSegments = nil
        stagedExportCaptionLeadingGap = nil
        stagedExportCaptionStyle = nil
    }

    func syncSubscriptionAfterAuth(userId: UUID) async {
        await SubscriptionManager.shared.logIn(appUserID: userId.uuidString)
        await SubscriptionManager.shared.fetchStatus()
        await SubscriptionManager.shared.syncToAppState(self)
    }

    func bootstrap(router: AppRouter) async {
        isBootstrapping = true
        defer { isBootstrapping = false }

        guard UserDefaults.standard.bool(forKey: Self.hasCompletedOnboardingKey) else {
            authStatus = .firstLaunch
            return
        }

        if let url = pendingIncomingURL, url.host == "auth" {
            pendingIncomingURL = nil
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
            await finishPendingSubscriptionDeepLink(router: router)
            return
        }

        currentUser = nil
        authStatus = .unauthenticated
        router.navigate(to: .login)
        await finishPendingSubscriptionDeepLink(router: router)
    }

    private func finishPendingSubscriptionDeepLink(router: AppRouter) async {
        guard let url = pendingIncomingURL, SubscriptionDeepLink.isSuccessURL(url) else { return }
        pendingIncomingURL = nil
        await handleSubscriptionSuccess(url, router: router)
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

    func queueIncomingURL(_ url: URL) {
        pendingIncomingURL = url
    }

    func handleIncomingURL(_ url: URL, router: AppRouter) async {
        guard url.scheme == AuthConstants.callbackScheme else { return }

        if SubscriptionDeepLink.isSuccessURL(url) {
            pendingIncomingURL = url
            if authStatus == .authenticated {
                pendingIncomingURL = nil
                await handleSubscriptionSuccess(url, router: router)
            }
            return
        }

        if url.host == "auth" {
            pendingIncomingURL = url
            await processAuthCallbackIfNeeded(router: router)
        }
    }

    func processAuthCallbackIfNeeded(router: AppRouter) async {
        guard let url = pendingIncomingURL, url.host == "auth" else { return }
        pendingIncomingURL = nil
        await processAuthCallbackURL(url, router: router)
    }

    func handleSubscriptionSuccess(_ url: URL, router: AppRouter) async {
        AppActivation.bringToForeground()

        guard authStatus == .authenticated, let userId = currentUser?.id else {
            pendingIncomingURL = url
            return
        }

        if let linkedID = SubscriptionDeepLink.appUserID(from: url),
           linkedID.lowercased() != userId.uuidString.lowercased() {
            #if DEBUG
            print("[AppState] subscription deep link app_user_id mismatch — refreshing signed-in user")
            #endif
        }

        await SubscriptionManager.shared.refreshAfterWebPurchase(appUserID: userId.uuidString)
        await SubscriptionManager.shared.syncToAppState(self)

        if isPro {
            pendingSubscriptionSuccessMessage = "Welcome to \(AppBranding.proName)! Your subscription is active."
            router.selectSidebar(.account)
        } else {
            pendingSubscriptionSuccessMessage =
                "Payment received. If Pro hasn’t unlocked yet, wait a moment and tap Refresh Subscription in Account."
            router.selectSidebar(.account)
        }
    }

    func consumePendingSubscriptionSuccessMessage() -> String? {
        defer { pendingSubscriptionSuccessMessage = nil }
        return pendingSubscriptionSuccessMessage
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
