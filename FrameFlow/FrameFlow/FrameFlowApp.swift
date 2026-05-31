//
//  FrameFlowApp.swift
//  FrameFlow
//
//  Created by Simranjit Singh Babbar on 25/05/2026.
//

import SwiftUI

@main
struct FrameFlowApp: App {
    @State private var appState = AppState()
    @State private var router = AppRouter()
    @State private var subscriptionManager = SubscriptionManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(router)
                .environment(SettingsStore.shared)
                .environment(subscriptionManager)
                .onAppear {
                    subscriptionManager.configureIfNeeded()
                    SettingsStore.shared.resetExpiryBannerDismissedForLaunch()
                }
        }
        .defaultSize(width: 1100, height: 700)
    }
}
