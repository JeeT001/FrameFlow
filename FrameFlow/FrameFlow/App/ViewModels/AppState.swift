//
//  AppState.swift
//  FrameFlow
//

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

    var isPro: Bool {
        subscriptionStatus == .active
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

    func markAuthenticated(user: User) {
        currentUser = user
        authStatus = .authenticated
    }

    func signOut() async {
        do {
            try await AuthService.shared.signOut()
        } catch {
            // Clear local auth state even if the network sign-out fails.
        }
        currentUser = nil
        authStatus = .unauthenticated
    }
}
