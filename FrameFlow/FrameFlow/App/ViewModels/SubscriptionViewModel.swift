//
//  SubscriptionViewModel.swift
//  FrameFlow
//

import Foundation
import RevenueCat
import Supabase

struct SubscriptionFeatureRow: Identifiable {
    let id = UUID()
    let title: String
    let freeIncluded: Bool
    let proIncluded: Bool
}

@Observable
@MainActor
final class SubscriptionViewModel {
    static let featureRows: [SubscriptionFeatureRow] = [
        SubscriptionFeatureRow(title: "Up to 2 windows", freeIncluded: true, proIncluded: true),
        SubscriptionFeatureRow(title: "Up to 4 windows", freeIncluded: false, proIncluded: true),
        SubscriptionFeatureRow(title: "9:16 vertical format", freeIncluded: false, proIncluded: true),
        SubscriptionFeatureRow(title: "System & combined audio", freeIncluded: false, proIncluded: true),
        SubscriptionFeatureRow(title: "Camera PiP overlay", freeIncluded: false, proIncluded: true),
        SubscriptionFeatureRow(title: "Auto captions editor", freeIncluded: false, proIncluded: true),
        SubscriptionFeatureRow(title: "1080p & 4K export", freeIncluded: false, proIncluded: true),
        SubscriptionFeatureRow(title: "No watermark", freeIncluded: false, proIncluded: true),
    ]

    private let subscriptionManager = SubscriptionManager.shared

    var isPurchasing = false
    var isRestoring = false
    var errorMessage: String?
    var showErrorAlert = false
    var showRestoreSuccessAlert = false

    var isConfigured: Bool { subscriptionManager.isConfigured }
    var isLoadingOfferings: Bool { subscriptionManager.isFetchingOfferings }
    var offeringsError: String? { subscriptionManager.lastError }
    var hasPackages: Bool { !subscriptionManager.availablePackages.isEmpty }
    var usesWebCheckout: Bool { subscriptionManager.usesWebCheckout }
    var canShowPlans: Bool { subscriptionManager.canPresentPlans }

    func loadOfferings() async {
        await subscriptionManager.fetchOfferings()
    }

    func refreshSubscriptionStatus(appState: AppState) async {
        if usesWebCheckout, let userID = appState.currentUser?.id.uuidString {
            await subscriptionManager.logIn(appUserID: userID)
        }
        await subscriptionManager.fetchStatus(forceRefresh: usesWebCheckout)
        subscriptionManager.syncToAppState(appState)
    }

    func monthlyPackage() -> Package? {
        subscriptionManager.package(for: .monthly)
    }

    func annualPackage() -> Package? {
        subscriptionManager.package(for: .annual)
    }

    func lifetimePackage() -> Package? {
        subscriptionManager.package(for: .lifetime)
    }

    func purchaseWeb(plan: SubscriptionPlan, appState: AppState) async {
        guard let userID = appState.currentUser?.id.uuidString else {
            errorMessage = SubscriptionManagerError.notSignedIn.localizedDescription
            showErrorAlert = true
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            _ = try subscriptionManager.openWebCheckout(plan: plan, appUserID: userID)
            AnalyticsService.trackUpgradeClicked(source: "subscription_web_\(plan.rawValue)")
        } catch {
            errorMessage = SubscriptionManager.userFacingMessage(for: error)
            showErrorAlert = true
        }
    }

    func purchase(
        package: Package,
        appState: AppState,
        router: AppRouter
    ) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await subscriptionManager.purchase(package: package)
            await subscriptionManager.fetchStatus()
            subscriptionManager.syncToAppState(appState)
            AnalyticsService.trackPurchaseCompleted(plan: Self.analyticsPlanName(for: package))
            router.selectSidebar(.home)
        } catch SubscriptionManagerError.userCancelled {
            return
        } catch {
            errorMessage = SubscriptionManager.userFacingMessage(for: error)
            showErrorAlert = true
        }
    }

    func restorePurchases(appState: AppState) async {
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await subscriptionManager.restorePurchases(
                appUserID: appState.currentUser?.id.uuidString
            )
            subscriptionManager.syncToAppState(appState)
            showRestoreSuccessAlert = true
        } catch SubscriptionManagerError.userCancelled {
            return
        } catch {
            errorMessage = SubscriptionManager.userFacingMessage(for: error)
            showErrorAlert = true
        }
    }

    private static func analyticsPlanName(for package: Package) -> String {
        let productId = package.storeProduct.productIdentifier.lowercased()
        if productId.contains("lifetime") { return "lifetime" }
        if productId.contains("annual") { return "annual" }
        if productId.contains("monthly") { return "monthly" }
        return package.identifier.lowercased()
    }
}
