//
//  AnalyticsService.swift
//  FrameFlow
//

import Foundation
import PostHog

enum AnalyticsService {
    private static var isConfigured = false

    static func configure(postHogAPIKey: String) {
        let key = postHogAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }

        let config = PostHogConfig(apiKey: key, host: "https://us.i.posthog.com")
        PostHogSDK.shared.setup(config)
        isConfigured = true
    }

    static func identify(userID: String) {
        guard isConfigured else { return }
        PostHogSDK.shared.identify(userID)
    }

    static func reset() {
        guard isConfigured else { return }
        PostHogSDK.shared.reset()
    }

    static func trackSignUp(method: String) {
        capture("sign_up", properties: ["method": method])
    }

    static func trackRecordingStarted(windowCount: Int, format: String, layout: String) {
        capture("recording_started", properties: [
            "window_count": windowCount,
            "format": format,
            "layout": layout,
        ])
    }

    static func trackRecordingCompleted(duration: Int, format: String) {
        capture("recording_completed", properties: [
            "duration_seconds": duration,
            "format": format,
        ])
    }

    static func trackExportCompleted(resolution: String, hasCaptions: Bool, hasCamera: Bool) {
        capture("export_completed", properties: [
            "resolution": resolution,
            "has_captions": hasCaptions,
            "has_camera": hasCamera,
        ])
    }

    static func trackUpgradeClicked(source: String) {
        capture("upgrade_clicked", properties: ["source": source])
    }

    static func trackPurchaseCompleted(plan: String) {
        capture("purchase_completed", properties: ["plan": plan])
    }

    static func trackFeatureBlocked(feature: String) {
        capture("feature_blocked", properties: ["feature": feature])
    }

    private static func capture(_ event: String, properties: [String: Any]? = nil) {
        guard isConfigured else { return }
        PostHogSDK.shared.capture(event, properties: properties)
    }
}
