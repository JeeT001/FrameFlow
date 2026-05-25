//
//  OnboardingView.swift
//  FrameFlow
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "hand.wave")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 10) {
                Text("Welcome to FrameFlow")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Pick your windows, choose a layout, record, and export — all from one native macOS app.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 440)
            }

            Button("Get Started") {
                appState.completeOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
