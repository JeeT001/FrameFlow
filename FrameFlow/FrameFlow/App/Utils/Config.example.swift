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

    /// RevenueCat public API key (Dashboard → Project → API keys).
    /// Day 31 dev: use Test Store key (`test_...`); entitlement identifier `pro`.
    static let revenueCatAPIKey = ""

    /// Sentry DSN (Project Settings → Client Keys)
    static let sentryDSN = ""

    /// PostHog project API key
    static let postHogAPIKey = ""
}
