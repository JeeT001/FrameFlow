// Copy this file to Config.swift in the same folder and add your real keys locally.
// Config.swift is gitignored and must never be committed.
//
//  Config.example.swift
//  FrameFlow
//

import Foundation

enum Config {
    /// Supabase project URL (Project Settings → API → Project URL)
    static let supabaseURL = ""

    /// Supabase anon/public key (Project Settings → API → anon public)
    static let supabaseAnonKey = ""

    /// RevenueCat public API key (Dashboard → Project → API keys)
    static let revenueCatAPIKey = ""

    /// Sentry DSN (Project Settings → Client Keys)
    static let sentryDSN = ""

    /// PostHog project API key
    static let postHogAPIKey = ""
}
