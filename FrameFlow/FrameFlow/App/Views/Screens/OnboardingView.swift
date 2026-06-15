//
//  OnboardingView.swift
//  FrameFlow
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "square.grid.2x2",
            title: "Pick Your Windows",
            subtitle: "Select the app windows you want in your recording. \(AppBranding.name) captures each window separately for a clean composite."
        ),
        OnboardingPage(
            systemImage: "rectangle.split.2x1",
            title: "Choose Your Layout",
            subtitle: "Arrange windows stacked, side by side, or picture-in-picture. Preview your layout before you hit record."
        ),
        OnboardingPage(
            systemImage: "video",
            title: "Record and Export",
            subtitle: "Record with optional captions and camera PiP, then export in 9:16 or 16:9 for social platforms."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            BrandLogoView(style: .onboarding)
                .padding(.top, 24)
                .padding(.bottom, 8)

            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageContent(page)
                        .tag(index)
                }
            }
            .tabViewStyle(.automatic)
            .frame(maxHeight: .infinity)

            pageIndicator

            actionBar
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            Image(systemName: page.systemImage)
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .frame(height: 80)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? AppColors.primary : AppColors.border)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var actionBar: some View {
        if currentPage < pages.count - 1 {
            Button("Next") {
                withAnimation {
                    currentPage = min(currentPage + 1, pages.count - 1)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .frame(maxWidth: 280)
        } else {
            VStack(spacing: 12) {
                Button("Sign Up") {
                    finishOnboarding(andNavigateTo: .signUp)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: 280)

                Button("Log In") {
                    finishOnboarding(andNavigateTo: .login)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: 280)
            }
        }
    }

    private func finishOnboarding(andNavigateTo route: AppRoute) {
        appState.completeOnboarding()
        router.navigate(to: route)
    }
}

private struct OnboardingPage {
    let systemImage: String
    let title: String
    let subtitle: String
}

#Preview {
    OnboardingView()
        .environment(AppState())
        .environment(AppRouter())
}
