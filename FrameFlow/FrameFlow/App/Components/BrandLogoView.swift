//
//  BrandLogoView.swift
//  FrameFlow
//

import SwiftUI

/// Horizontal brand wordmark from `BrandLogoWordmark` asset (1024×319).
struct BrandLogoView: View {
    enum Style {
        /// Sidebar header (~168pt wide).
        case sidebar
        /// Auth screens above the sign-in card (~220pt wide).
        case authHero
        /// Profile / Account header.
        case profile
        /// Onboarding top bar.
        case onboarding
    }

    let style: Style

    var body: some View {
        Image("BrandLogoWordmark")
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .aspectRatio(contentMode: .fit)
            .frame(width: width, height: height)
            .accessibilityLabel(AppBranding.name)
    }

    private var width: CGFloat? {
        switch style {
        case .sidebar: 168
        case .authHero: 220
        case .profile: 200
        case .onboarding: 200
        }
    }

    private var height: CGFloat? {
        switch style {
        case .sidebar: 36
        case .authHero: 48
        case .profile: 44
        case .onboarding: 44
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        BrandLogoView(style: .sidebar)
        BrandLogoView(style: .authHero)
        BrandLogoView(style: .profile)
    }
    .padding()
    .background(AppColors.background)
}
