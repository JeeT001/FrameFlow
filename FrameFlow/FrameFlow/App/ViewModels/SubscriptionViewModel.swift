//
//  SubscriptionViewModel.swift
//  FrameFlow
//

import Foundation
import RevenueCat

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
    var errorMessage: String?
    var showErrorAlert = false

    var isConfigured: Bool { subscriptionManager.isConfigured }
    var isLoadingOfferings: Bool { subscriptionManager.isFetchingOfferings }
    var offeringsError: String? { subscriptionManager.lastError }
    var hasPackages: Bool { !subscriptionManager.availablePackages.isEmpty }

    func loadOfferings() async {
        await subscriptionManager.fetchOfferings()
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
            router.selectSidebar(.home)
        } catch SubscriptionManagerError.userCancelled {
            return
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
