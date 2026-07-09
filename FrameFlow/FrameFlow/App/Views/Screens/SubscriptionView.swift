//
//  SubscriptionView.swift
//  FrameFlow
//

import RevenueCat
import SwiftUI

struct SubscriptionView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = SubscriptionViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                headerSection
                featureComparisonSection

                if viewModel.isLoadingOfferings {
                    ProgressView("Loading plans…")
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else if !viewModel.isConfigured {
                    setupRequiredView(message: "Add your RevenueCat API key to Config.swift to enable purchases.")
                } else if !viewModel.canShowPlans {
                    setupRequiredView(message: setupMessage)
                } else {
                    planCardsSection
                    if viewModel.usesWebCheckout {
                        webCheckoutFooter
                    }
                }

                if viewModel.isConfigured {
                    restoreSection
                }
            }
            .padding(28)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(AppBranding.proName)
        .overlay {
            if viewModel.isPurchasing || viewModel.isRestoring {
                ZStack {
                    Color.black.opacity(0.25)
                    ProgressView(viewModel.isRestoring ? "Refreshing subscription…" : "Processing purchase…")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .ignoresSafeArea()
            }
        }
        .task {
            await viewModel.loadOfferings()
        }
        .onAppear {
            if appState.isPro {
                router.selectSidebar(.account)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await viewModel.refreshSubscriptionStatus(appState: appState)
            }
        }
        .alert("Purchase failed", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
        .alert("Purchase restored", isPresented: $viewModel.showRestoreSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your Pro subscription is active on this device.")
        }
    }

    private var restoreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(viewModel.usesWebCheckout ? "Refresh Subscription" : "Restore Purchase") {
                Task {
                    await viewModel.restorePurchases(appState: appState)
                }
            }
            .disabled(viewModel.isPurchasing || viewModel.isRestoring)

            Text(
                viewModel.usesWebCheckout
                    ? "After browser checkout, return here and tap Refresh Subscription to unlock Pro on this Mac."
                    : "Already subscribed? Restore to unlock Pro on this Mac after reinstalling."
            )
            .font(.caption)
            .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upgrade to Pro")
                .font(.largeTitle.weight(.bold))

            Text("Unlock vertical exports, multi-window recording, system audio, and HD export without a watermark.")
                .font(.body)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var featureComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compare plans")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("Feature")
                        .font(.subheadline.weight(.semibold))
                    Text("Free")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                    Text("Pro")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }

                Divider()
                    .gridCellColumns(3)

                ForEach(SubscriptionViewModel.featureRows) { row in
                    GridRow {
                        Text(row.title)
                            .font(.subheadline)
                        featureMark(row.freeIncluded)
                        featureMark(row.proIncluded)
                    }
                }
            }
            .padding(16)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var planCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a plan")
                .font(.headline)

            HStack(alignment: .top, spacing: 16) {
                planCard(
                    title: "Pro Annual",
                    priceLine: "$9/mo",
                    detailLine: "Billed $108/yr · 7-day free trial",
                    buttonTitle: "Start Free Trial",
                    plan: .annual
                )

                planCard(
                    title: "Pro Monthly",
                    priceLine: "$19/mo",
                    detailLine: "7-day free trial",
                    buttonTitle: "Start Free Trial",
                    plan: .monthly
                )

                if settingsStore.showLifetimeDeal {
                    planCard(
                        title: "Lifetime",
                        priceLine: "$79",
                        detailLine: "One-time purchase",
                        buttonTitle: "Get Lifetime",
                        plan: .lifetime
                    )
                }
            }
        }
    }

    private var webCheckoutFooter: some View {
        Text("Checkout opens in your browser (Stripe). When finished, return here and tap Refresh Subscription if Pro hasn’t unlocked yet.")
            .font(.caption)
            .foregroundStyle(AppColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func planCard(
        title: String,
        priceLine: String,
        detailLine: String,
        buttonTitle: String,
        plan: SubscriptionPlan
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            Text(priceLine)
                .font(.title2.weight(.bold))

            Text(detailLine)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)

            Spacer(minLength: 0)

            Button(buttonTitle) {
                Task {
                    if viewModel.usesWebCheckout {
                        await viewModel.purchaseWeb(plan: plan, appState: appState)
                    } else if let package = packageForPlan(plan) {
                        await viewModel.purchase(package: package, appState: appState, router: router)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(viewModel.isPurchasing)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .background(AppColors.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(AppColors.primary.opacity(0.2))
        )
    }

    private func packageForPlan(_ plan: SubscriptionPlan) -> Package? {
        switch plan {
        case .monthly: viewModel.monthlyPackage()
        case .annual: viewModel.annualPackage()
        case .lifetime: viewModel.lifetimePackage()
        }
    }

    private func featureMark(_ included: Bool) -> some View {
        Group {
            if included {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.successGreen)
            } else {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func setupRequiredView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Plans not available yet", systemImage: "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(AppColors.proGold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("See Docs/DEV_LOG.md — Day 54 Web Billing checkout setup.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.proGold.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private var setupMessage: String {
        if viewModel.usesWebCheckout {
            return "Plans are ready. If checkout fails, verify webPurchaseLinkBaseURL and package IDs in Config.swift match RevenueCat."
        }
        if let error = viewModel.offeringsError, !error.isEmpty {
            return error
        }
        return "Add webPurchaseLinkBaseURL to Config.swift, or complete RevenueCat product setup for the Default offering."
    }
}

#Preview {
    SubscriptionView()
        .environment(AppState())
        .environment(AppRouter())
        .environment(SubscriptionManager.shared)
        .environment(SettingsStore.shared)
        .frame(width: 900, height: 700)
}
