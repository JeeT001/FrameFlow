// Copy this file to Config.swift in the same folder and add your real keys locally.
// Config.swift is gitignored and must never be committed.
//
//  Config.example.swift
//  FrameFlow
//

import Foundation

enum Config {
    /// Supabase project URL (Project Settings → API → Project URL)
    static let supabaseURL = "https://rdqohexzpxrkggcagrmq.supabase.co"

    /// Supabase anon/public key (Project Settings → API → anon public)
    static let supabaseAnonKey = "sb_publishable_Z68W_NZiDm1u_ouq7Glk1g_HUWJyUtU"

    /// RevenueCat Apple/macOS public API key (Apps & providers → your app → Public API key).
    /// Use `appl_...` for entitlements and restore — not Test Store (`test_...`) or Web Billing (`rcb_...`).
    static let revenueCatAPIKey = ""

    /// Production Web Purchase Link base URL (RevenueCat → Funnels → Purchase Links → Production).
    /// Example: `https://pay.rev.cat/xxxxxxxx/` — App User ID is appended to the path at checkout.
    /// Also set Purchase Link success redirect to `SubscriptionDeepLink.successRedirectURL` in RevenueCat.
    static let webPurchaseLinkBaseURL = ""

    /// Package IDs for `package_id` query param. Match identifiers on packages in your Default offering
    /// (e.g. `$Drazlo_pro_monthly`, not generic `$rc_monthly`, unless that is what RC shows).
    static let webPurchasePackageMonthly = "$rc_monthly"
    static let webPurchasePackageAnnual = "$rc_annual"
    static let webPurchasePackageLifetime = "lifetime"

    /// Sentry DSN (Project Settings → Client Keys)
    static let sentryDSN = ""

    /// PostHog project API key
    static let postHogAPIKey = ""

    /// Day 52 — Typeform or Google Forms URL for in-app feedback prompt.
    static let feedbackFormURL = ""
}
