//
//  SubscriptionManager.swift
//  FrameFlow
//

import AppKit
import Foundation
import RevenueCat

enum SubscriptionPlan: String, CaseIterable, Sendable {
    case monthly
    case annual
    case lifetime
}

enum SubscriptionManagerError: LocalizedError {
    case notConfigured
    case userCancelled
    case noOfferings
    case restoreFailedNoActiveSubscription

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "RevenueCat is not configured. Add your API key to Config.swift."
        case .userCancelled:
            "Purchase cancelled."
        case .noOfferings:
            "No subscription plans are available yet. Complete RevenueCat product setup."
        case .restoreFailedNoActiveSubscription:
            "No active Pro subscription was found for this account."
        }
    }
}

@MainActor
@Observable
final class SubscriptionManager: NSObject {
    static let shared = SubscriptionManager()

    static let proEntitlementID = "pro"

    var isPro = false
    var subscriptionStatus = "free"
    var planName = "Free"
    var renewalDate: Date?
    var isConfigured = false
    var isLoading = false
    var lastError: String?
    var currentOffering: Offering?
    var availablePackages: [Package] = []
    var isFetchingOfferings = false

    private var didConfigure = false
    private var customerInfoTask: Task<Void, Never>?

    private override init() {
        super.init()
    }

    func configureIfNeeded() {
        let key = Config.revenueCatAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            isConfigured = false
            return
        }

        guard !didConfigure else {
            isConfigured = true
            return
        }

        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        Purchases.configure(withAPIKey: key)
        Purchases.shared.delegate = self
        didConfigure = true
        isConfigured = true

        customerInfoTask?.cancel()
        customerInfoTask = Task { [weak self] in
            for await customerInfo in Purchases.shared.customerInfoStream {
                guard !Task.isCancelled else { break }
                self?.applyCustomerInfo(customerInfo)
            }
        }
    }

    func logIn(appUserID: String) async {
        guard isConfigured else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(appUserID)
            applyCustomerInfo(customerInfo)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            #if DEBUG
            print("[SubscriptionManager] logIn failed: \(error.localizedDescription)")
            #endif
        }
    }

    func logOut() async {
        customerInfoTask?.cancel()
        customerInfoTask = nil

        guard isConfigured else {
            resetToFree()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.logOut()
            applyCustomerInfo(customerInfo)
            lastError = nil
        } catch {
            resetToFree()
            lastError = error.localizedDescription
            #if DEBUG
            print("[SubscriptionManager] logOut failed: \(error.localizedDescription)")
            #endif
        }

        if isConfigured {
            customerInfoTask = Task { [weak self] in
                for await customerInfo in Purchases.shared.customerInfoStream {
                    guard !Task.isCancelled else { break }
                    self?.applyCustomerInfo(customerInfo)
                }
            }
        }
    }

    func fetchOfferings() async {
        guard isConfigured else {
            currentOffering = nil
            availablePackages = []
            return
        }

        isFetchingOfferings = true
        defer { isFetchingOfferings = false }

        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            availablePackages = offerings.current?.availablePackages ?? []
            lastError = availablePackages.isEmpty
                ? "No packages in the current offering. Add products in RevenueCat Dashboard."
                : nil
        } catch {
            currentOffering = nil
            availablePackages = []
            lastError = error.localizedDescription
            #if DEBUG
            print("[SubscriptionManager] fetchOfferings failed: \(error.localizedDescription)")
            #endif
        }
    }

    func package(for plan: SubscriptionPlan) -> Package? {
        availablePackages.first { matchesPlan($0, plan: plan) }
    }

    func purchase(package: Package) async throws {
        guard isConfigured else { throw SubscriptionManagerError.notConfigured }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled {
                throw SubscriptionManagerError.userCancelled
            }
            applyCustomerInfo(result.customerInfo)
        } catch let error as SubscriptionManagerError {
            throw error
        } catch {
            throw Self.mapPurchaseError(error)
        }
    }

    func restorePurchases() async throws {
        guard isConfigured else { throw SubscriptionManagerError.notConfigured }

        isLoading = true
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            applyCustomerInfo(customerInfo)
            guard isPro else {
                throw SubscriptionManagerError.restoreFailedNoActiveSubscription
            }
        } catch let error as SubscriptionManagerError {
            throw error
        } catch {
            throw Self.mapPurchaseError(error)
        }
    }

    static func userFacingMessage(for error: Error) -> String {
        if let subscriptionError = error as? SubscriptionManagerError {
            return subscriptionError.localizedDescription
        }
        return mapPurchaseError(error).localizedDescription
    }

    private static func mapPurchaseError(_ error: Error) -> Error {
        if let subscriptionError = error as? SubscriptionManagerError {
            return subscriptionError
        }

        let nsError = error as NSError
        let combined = (nsError.localizedDescription + " " + (nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String ?? "")).lowercased()

        if combined.contains("cancel") {
            return SubscriptionManagerError.userCancelled
        }
        if combined.contains("card was declined")
            || combined.contains("declined")
            || combined.contains("insufficient")
            || combined.contains("9995") {
            return NSError(
                domain: "FrameFlow.Subscription",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Your payment was declined. Check your card details or try a different payment method."]
            )
        }
        if combined.contains("network") || combined.contains("offline") || combined.contains("internet") {
            return NSError(
                domain: "FrameFlow.Subscription",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not reach the billing service. Check your internet connection and try again."]
            )
        }

        return error
    }

    func fetchStatus() async {
        guard isConfigured else {
            resetToFree()
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            applyCustomerInfo(customerInfo)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            #if DEBUG
            print("[SubscriptionManager] fetchStatus failed: \(error.localizedDescription)")
            #endif
        }
    }

    func applyCustomerInfo(_ info: CustomerInfo) {
        guard let pro = info.entitlements[Self.proEntitlementID] else {
            resetToFree()
            return
        }

        planName = Self.planDisplayName(for: pro.productIdentifier)
        renewalDate = pro.expirationDate

        if pro.isActive {
            isPro = true
            if pro.periodType == .trial {
                subscriptionStatus = "trialing"
            } else if pro.billingIssueDetectedAt != nil {
                subscriptionStatus = "past_due"
            } else if pro.unsubscribeDetectedAt != nil, !pro.willRenew {
                subscriptionStatus = "cancelled"
            } else {
                subscriptionStatus = "active"
            }
            return
        }

        isPro = false
        if pro.billingIssueDetectedAt != nil {
            subscriptionStatus = "past_due"
        } else if pro.unsubscribeDetectedAt != nil {
            subscriptionStatus = "cancelled"
        } else {
            subscriptionStatus = "expired"
        }
    }

    func syncToAppState(_ appState: AppState) {
        if isPro {
            appState.subscriptionStatus = subscriptionStatus == "past_due" ? .past_due : .active
            return
        }

        switch subscriptionStatus {
        case "past_due":
            appState.subscriptionStatus = .past_due
        case "expired", "cancelled":
            appState.subscriptionStatus = .expired
        default:
            appState.subscriptionStatus = .free
        }
    }

    @discardableResult
    func showManageSubscriptions() async -> Bool {
        guard isConfigured else {
            lastError = "RevenueCat is not configured. Open Subscription to view plans."
            return false
        }

        do {
            try await Purchases.shared.showManageSubscriptions()
            lastError = nil
            return true
        } catch {
            return await openManagementURLFallback()
        }
    }

    // MARK: - Private

    private func resetToFree() {
        isPro = false
        subscriptionStatus = "free"
        planName = "Free"
        renewalDate = nil
    }

    private func openManagementURLFallback() async -> Bool {
        do {
            let info = try await Purchases.shared.customerInfo()
            if let url = info.managementURL {
                NSWorkspace.shared.open(url)
                lastError = nil
                return true
            }
        } catch {
            lastError = error.localizedDescription
        }

        lastError = "Subscription management is not available in-app yet. Use Renew on the Subscription screen."
        #if DEBUG
        print("[SubscriptionManager] showManageSubscriptions unavailable — Test Store has no billing portal")
        #endif
        return false
    }

    private static func planDisplayName(for productIdentifier: String) -> String {
        let id = productIdentifier.lowercased()
        if id.contains("lifetime") { return "Lifetime" }
        if id.contains("annual") { return "Pro Annual" }
        if id.contains("monthly") { return "Pro Monthly" }
        return "Pro"
    }

    private func matchesPlan(_ package: Package, plan: SubscriptionPlan) -> Bool {
        let productId = package.storeProduct.productIdentifier.lowercased()
        let packageId = package.identifier.lowercased()

        switch plan {
        case .monthly:
            return productId.contains("monthly")
                || packageId.contains("monthly")
                || package.packageType == .monthly
        case .annual:
            return productId.contains("annual")
                || packageId.contains("annual")
                || package.packageType == .annual
        case .lifetime:
            return productId.contains("lifetime")
                || packageId.contains("lifetime")
                || package.packageType == .lifetime
        }
    }
}

extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.applyCustomerInfo(customerInfo)
        }
    }
}
