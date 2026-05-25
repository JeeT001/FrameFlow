//
//  RootView.swift
//  FrameFlow
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
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
        .task {
            guard !hasBootstrapped else { return }
            hasBootstrapped = true
            await appState.bootstrap(router: router)
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .environment(AppRouter())
}
