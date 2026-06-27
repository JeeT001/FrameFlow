//
//  FrameFlowApp.swift
//  FrameFlow
//
//  Created by Simranjit Singh Babbar on 25/05/2026.
//

import Sentry
import Sparkle
import SwiftUI

@main
struct FrameFlowApp: App {
    @State private var appState = AppState()
    @State private var router = AppRouter()
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var updaterController = AppUpdaterController()

    init() {
        let dsn = Config.sentryDSN.trimmingCharacters(in: .whitespacesAndNewlines)
        if !dsn.isEmpty {
            SentrySDK.start { options in
                options.dsn = dsn
                options.tracesSampleRate = 0.2
            }
        }
        AnalyticsService.configure(postHogAPIKey: Config.postHogAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(router)
                .environment(SettingsStore.shared)
                .environment(subscriptionManager)
                .environment(updaterController)
                .onAppear {
                    subscriptionManager.configureIfNeeded()
                    SettingsStore.shared.resetExpiryBannerDismissedForLaunch()
                    if appState.isPro {
                        TranscriptionService.shared.prepareModelInBackground()
                    }
                }
                .onChange(of: appState.isPro) { _, isPro in
                    if isPro {
                        TranscriptionService.shared.prepareModelInBackground()
                    }
                }
                .onOpenURL { url in
                    Task {
                        await appState.handleIncomingURL(url, router: router)
                    }
                }
        }
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    updaterController.checkForUpdates()
                }
            }
        }
    }
}
