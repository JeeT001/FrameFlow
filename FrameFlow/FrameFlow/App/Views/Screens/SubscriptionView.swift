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
                    setupRequiredView(message: "Add your RevenueCat Test Store API key to Config.swift to enable purchases.")
                } else if !viewModel.hasPackages {
                    setupRequiredView(message: setupMessage)
                } else {
                    planCardsSection
                }
            }
            .padding(28)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("FrameFlow Pro")
        .overlay {
            if viewModel.isPurchasing {
                ZStack {
                    Color.black.opacity(0.25)
                    ProgressView("Processing purchase…")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .ignoresSafeArea()
            }
        }
        .task {
            await viewModel.loadOfferings()
        }
        .alert("Purchase failed", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upgrade to Pro")
                .font(.largeTitle.weight(.bold))

            Text("Unlock vertical exports, multi-window recording, system audio, captions, and HD export without a watermark.")
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
                if let package = viewModel.annualPackage() {
                    planCard(
                        title: "Pro Annual",
                        priceLine: "$9/mo",
                        detailLine: "Billed $108/yr · 7-day free trial",
                        buttonTitle: "Start Free Trial",
                        package: package
                    )
                }

                if let package = viewModel.monthlyPackage() {
                    planCard(
                        title: "Pro Monthly",
                        priceLine: "$19/mo",
                        detailLine: "7-day free trial",
                        buttonTitle: "Start Free Trial",
                        package: package
                    )
                }

                if settingsStore.showLifetimeDeal, let package = viewModel.lifetimePackage() {
                    planCard(
                        title: "Lifetime",
                        priceLine: "$79",
                        detailLine: "One-time purchase",
                        buttonTitle: "Get Lifetime",
                        package: package
                    )
                }
            }
        }
    }

    private func planCard(
        title: String,
        priceLine: String,
        detailLine: String,
        buttonTitle: String,
        package: Package
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
                    await viewModel.purchase(package: package, appState: appState, router: router)
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

            Text("See Docs/DEV_LOG.md — Day 32 RevenueCat Test Store setup checklist.")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.proGold.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private var setupMessage: String {
        if let error = viewModel.offeringsError, !error.isEmpty {
            return error
        }
        return "Complete RevenueCat product setup: create Test Store products, attach to entitlement pro, and add packages to the Default offering."
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
