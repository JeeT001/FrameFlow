//
//  RootView.swift
//  FrameFlow
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var hasBootstrapped = false

    var body: some View {
        Group {
            if appState.isBootstrapping {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                switch appState.authStatus {
                case .firstLaunch:
                    OnboardingView()
                case .unauthenticated:
                    AuthContainerView()
                case .authenticated:
                    MainAppView()
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(AppColors.background)
        .preferredColorScheme(preferredColorScheme)
        .onChange(of: subscriptionManager.subscriptionStatus) { _, _ in
            subscriptionManager.syncToAppState(appState)
            settingsStore.clearExpiryBannerDismissedIfRecovered(from: appState.subscriptionStatus)
        }
        .onChange(of: appState.subscriptionStatus) { _, newStatus in
            settingsStore.clearExpiryBannerDismissedIfRecovered(from: newStatus)
        }
        .task {
            guard !hasBootstrapped else { return }
            hasBootstrapped = true
            await appState.bootstrap(router: router)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch settingsStore.darkModeOverride {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .environment(AppRouter())
        .environment(SettingsStore.shared)
        .environment(SubscriptionManager.shared)
}
