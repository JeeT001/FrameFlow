//
//  SubscriptionDeepLink.swift
//  FrameFlow
//
//  After Stripe checkout, RevenueCat redirects here so macOS re-opens Drazlo and refreshes Pro.
//  Configure in RevenueCat → Funnels → Purchase Links → Success → Redirect to custom URL.
//

import Foundation

enum SubscriptionDeepLink {
    /// Paste into RevenueCat Purchase Link success redirect (Production + Sandbox).
    static let successRedirectURL = "\(AuthConstants.callbackScheme)://subscription/success"

    static func isSuccessURL(_ url: URL) -> Bool {
        guard url.scheme == AuthConstants.callbackScheme else { return false }
        guard url.host == "subscription" else { return false }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return path.isEmpty || path == "success"
    }

    static func appUserID(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems,
              let value = items.first(where: { $0.name == "app_user_id" })?.value
        else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
