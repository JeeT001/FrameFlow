//
//  WebPurchaseLink.swift
//  FrameFlow
//

import Foundation

enum WebPurchaseLink {
    /// Production Web Purchase Link from RevenueCat → Funnels → Purchase Links.
    /// Format: `https://pay.rev.cat/<token>/` — App User ID is appended to the **path**, not `?app_user_id=`.
    static var isConfigured: Bool {
        !trimmed(Config.webPurchaseLinkBaseURL).isEmpty
    }

    /// `https://pay.rev.cat/<token>/<appUserID>?package_id=...`
    static func url(appUserID: String, packageID: String?) -> URL? {
        let base = trimmed(Config.webPurchaseLinkBaseURL)
        guard !base.isEmpty else { return nil }

        let userID = trimmed(appUserID)
        guard !userID.isEmpty else { return nil }

        guard var components = URLComponents(string: base) else { return nil }
        components.path = pathWithAppUserID(components.path, appUserID: userID)

        var items = components.queryItems ?? []
        items.removeAll {
            $0.name == "app_user_id" || $0.name == "package_id" || $0.name == "skip_purchase_success"
        }

        let resolvedPackageID = trimmed(packageID ?? "")
        if !resolvedPackageID.isEmpty {
            items.append(URLQueryItem(name: "package_id", value: resolvedPackageID))
        }

        // Skip RevenueCat hosted success page — redirect straight to app deep link after payment.
        items.append(URLQueryItem(name: "skip_purchase_success", value: "true"))

        components.queryItems = items.isEmpty ? nil : items
        return components.url
    }

    /// Appends the App User ID to a RevenueCat-hosted checkout URL (path segment, not query param).
    static func url(appendingAppUserID appUserID: String, to checkoutURL: URL) -> URL {
        let userID = trimmed(appUserID)
        guard !userID.isEmpty else { return checkoutURL }

        guard var components = URLComponents(url: checkoutURL, resolvingAgainstBaseURL: false) else {
            return checkoutURL
        }

        if pathContainsAppUserID(components.path, appUserID: userID) {
            return checkoutURL
        }

        components.path = pathWithAppUserID(components.path, appUserID: userID)

        if var items = components.queryItems {
            items.removeAll { $0.name == "app_user_id" }
            components.queryItems = items.isEmpty ? nil : items
        }

        return components.url ?? checkoutURL
    }

    static func packageID(for plan: SubscriptionPlan) -> String {
        switch plan {
        case .monthly:
            return trimmed(Config.webPurchasePackageMonthly)
        case .annual:
            return trimmed(Config.webPurchasePackageAnnual)
        case .lifetime:
            return trimmed(Config.webPurchasePackageLifetime)
        }
    }

    private static func pathWithAppUserID(_ path: String, appUserID: String) -> String {
        var normalized = path
        if !normalized.hasSuffix("/") {
            normalized += "/"
        }
        normalized += encodedPathComponent(appUserID)
        return normalized
    }

    private static func pathContainsAppUserID(_ path: String, appUserID: String) -> Bool {
        path.hasSuffix("/\(appUserID)") || path.hasSuffix("/\(encodedPathComponent(appUserID))")
    }

    private static func encodedPathComponent(_ value: String) -> String {
        value.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))
        ) ?? value
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
