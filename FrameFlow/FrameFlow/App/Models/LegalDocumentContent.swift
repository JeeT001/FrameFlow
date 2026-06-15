//
//  LegalDocumentContent.swift
//  FrameFlow
//
//  When launching drazlo.app, copy section titles + body to static /privacy and /terms pages.
//  Set LegalConstants.websiteBaseURL. Optional later: fetch remote HTML/markdown with bundled fallback — out of scope for now.
//

import Foundation

enum LegalDocumentContent {
    private static let supportEmail = "kiwibooking.nz@gmail.com"
    private static let lastUpdated = "June 15, 2026"
    private static let draftDisclaimer =
        "This document is provided for informational purposes; consult legal counsel before launch."

    static var privacyPolicy: LegalDocument {
        LegalDocument(
            kind: .privacyPolicy,
            title: "Privacy Policy",
            lastUpdated: lastUpdated,
            sections: privacySections,
            draftDisclaimer: draftDisclaimer
        )
    }

    static var termsOfService: LegalDocument {
        LegalDocument(
            kind: .termsOfService,
            title: "Terms of Service",
            lastUpdated: lastUpdated,
            sections: termsSections,
            draftDisclaimer: draftDisclaimer
        )
    }

    // MARK: - Privacy Policy

    private static var privacySections: [LegalSection] {
        [
            LegalSection(
                title: "Introduction",
                body: """
                Welcome to \(AppBranding.name). This Privacy Policy explains how we collect, use, and protect information when you use our macOS screen-recording application and related account services.

                \(AppBranding.name) is operated from New Zealand. If you have questions about this policy, contact us at \(supportEmail).
                """
            ),
            LegalSection(
                title: "Information We Collect",
                body: """
                **Account information.** When you create an account, we collect your email address and display name through our authentication provider (Supabase). This lets you sign in, sync your profile, and manage your subscription across devices.

                **Subscription information.** If you subscribe to \(AppBranding.proName), we receive subscription status, plan type, and renewal information through RevenueCat and our payment processors (such as Stripe or Apple). We do not store your full payment card details on our servers.

                **Usage and diagnostics (optional).** If enabled in your build, we may collect anonymized product analytics (for example via PostHog) and crash reports (for example via Sentry) to improve stability and features. These tools do not receive your screen recordings or exported videos.

                **Support communications.** If you email us, we receive the content of your message and any information you choose to include.
                """
            ),
            LegalSection(
                title: "Information We Do Not Collect by Default",
                body: """
                **Your recordings stay on your Mac.** Screen captures, audio, camera picture-in-picture feeds, and exported MP4 files are processed and stored locally on your device unless you choose to save or share them elsewhere.

                **Captions are processed on-device.** When you generate captions, transcription runs locally using WhisperKit. Your audio is not sent to our servers for caption generation.

                **We do not upload your screen or microphone content** as part of normal app operation. We do not sell your personal information.
                """
            ),
            LegalSection(
                title: "macOS Permissions",
                body: """
                \(AppBranding.name) requests system permissions only to provide features you use:

                **Screen Recording** — to list windows, capture your selected apps, and produce recordings.

                **Camera** — for optional picture-in-picture camera overlay during recordings.

                **Microphone** — when you choose an audio mode that includes your voice.

                **Accessibility** — to enable global keyboard shortcuts during recording when another app is focused. Local shortcuts work without this permission when \(AppBranding.name) is in the foreground.

                You can review or revoke permissions at any time in System Settings → Privacy & Security.
                """
            ),
            LegalSection(
                title: "How Data Is Stored",
                body: """
                **On your Mac:** Recording metadata, app preferences, and staging files are stored in your user Library (Application Support). Exported videos are saved to the folder you choose in Settings.

                **In the cloud:** Account and subscription records are stored with our service providers (Supabase and RevenueCat) as needed to operate sign-in and billing.

                **Security-scoped bookmarks:** If you pick a custom save folder, macOS stores a security-scoped bookmark so the app can write exports without repeated permission prompts.
                """
            ),
            LegalSection(
                title: "Third-Party Services",
                body: """
                We use trusted third parties to operate \(AppBranding.name):

                • **Supabase** — authentication and user profile storage
                • **RevenueCat** — subscription management and entitlements
                • **Stripe / Apple** — payment processing (handled by those platforms; subject to their privacy policies)
                • **PostHog** (if configured) — product analytics
                • **Sentry** (if configured) — crash and error reporting

                Each provider processes data according to its own privacy policy. We share only what is necessary to provide the service.
                """
            ),
            LegalSection(
                title: "Data Retention and Deletion",
                body: """
                We retain account information while your account is active. You may delete your account from Profile → Delete Account in the app. Deletion removes your profile and associated subscription records from our systems, subject to reasonable backup and legal retention requirements.

                Recordings and exports on your Mac are under your control. Uninstalling the app or deleting files locally removes that content from your device.
                """
            ),
            LegalSection(
                title: "Children's Privacy",
                body: """
                \(AppBranding.name) is not directed at children under 13. We do not knowingly collect personal information from children. If you believe a child has provided us with personal information, contact us at \(supportEmail) and we will take steps to delete it.
                """
            ),
            LegalSection(
                title: "International Users",
                body: """
                \(AppBranding.name) is operated from New Zealand. If you access the app from other countries, your information may be processed in New Zealand and in countries where our service providers operate. By using the app, you consent to this transfer and processing as described in this policy.
                """
            ),
            LegalSection(
                title: "Changes to This Policy",
                body: """
                We may update this Privacy Policy from time to time. We will revise the "Last updated" date at the top of this document. Continued use of \(AppBranding.name) after changes take effect constitutes acceptance of the updated policy. For material changes, we may provide additional notice in the app.
                """
            ),
            LegalSection(
                title: "Contact Us",
                body: """
                For privacy questions or requests, email \(supportEmail). Please include enough detail for us to verify your account and respond to your request.
                """
            ),
        ]
    }

    // MARK: - Terms of Service

    private static var termsSections: [LegalSection] {
        [
            LegalSection(
                title: "Acceptance of Terms",
                body: """
                By downloading, installing, or using \(AppBranding.name), you agree to these Terms of Service and our Privacy Policy. If you do not agree, do not use the app.

                These terms apply to the \(AppBranding.name) macOS application, your account, and any updates we provide.
                """
            ),
            LegalSection(
                title: "Eligibility and Your Account",
                body: """
                You must be at least 13 years old to create an account. You are responsible for maintaining the confidentiality of your login credentials and for all activity under your account.

                You agree to provide accurate information when signing up and to notify us at \(supportEmail) if you suspect unauthorized access to your account.
                """
            ),
            LegalSection(
                title: "Description of Service",
                body: """
                \(AppBranding.name) is a screen-recording application for macOS. Features may include window selection, layout presets, live preview, camera picture-in-picture, audio capture, on-device captions (\(AppBranding.proName)), and export to common video formats.

                We may add, change, or remove features over time. Some capabilities require macOS permissions or a supported Mac model.
                """
            ),
            LegalSection(
                title: "Free and Pro Plans",
                body: """
                **Free tier** includes core recording and export with certain limits (such as window count, resolution, or watermark on exports).

                **\(AppBranding.proName)** unlocks additional features such as higher resolutions, vertical layouts, system audio modes, captions, and watermark-free exports. Plan details are shown in the app at purchase time.

                Subscriptions are billed through RevenueCat and processed by Apple, Stripe, or other payment providers we support. **Trials and auto-renewal:** If you start a trial or subscription, it may renew automatically unless you cancel before the renewal date. Manage or cancel through your App Store account, Stripe customer portal, or the in-app subscription management options.

                **Refunds** are handled by the payment provider (Apple or Stripe) according to their policies. We do not guarantee refunds outside those channels.
                """
            ),
            LegalSection(
                title: "Acceptable Use",
                body: """
                You agree not to use \(AppBranding.name) to:

                • Record or distribute content without permission of the people or rights holders involved
                • Violate any applicable law or third-party terms
                • Circumvent digital rights management or access controls
                • Upload malware, spam, or abusive material through support channels
                • Reverse engineer, decompile, or attempt to extract source code except where permitted by law
                • Interfere with the app's operation or other users' access to services

                You are solely responsible for the content you record and export.
                """
            ),
            LegalSection(
                title: "Intellectual Property",
                body: """
                **Your content.** You retain ownership of recordings and exports you create. We do not claim ownership of your videos.

                **Our property.** The \(AppBranding.name) app, logo, UI, documentation, and underlying software are owned by us or our licensors and are protected by intellectual property laws. These terms do not grant you any rights to our trademarks or brand assets except limited use necessary to use the app.
                """
            ),
            LegalSection(
                title: "Disclaimers",
                body: """
                \(AppBranding.name) is provided **"as is"** and **"as available"** without warranties of any kind, whether express or implied, including merchantability, fitness for a particular purpose, and non-infringement.

                We do not warrant that the app will be uninterrupted, error-free, or compatible with every Mac configuration. Recording quality and performance depend on your hardware, macOS version, and system load.
                """
            ),
            LegalSection(
                title: "Limitation of Liability",
                body: """
                To the maximum extent permitted by law, we and our suppliers will not be liable for any indirect, incidental, special, consequential, or punitive damages, or for loss of profits, data, or goodwill, arising from your use of \(AppBranding.name).

                Our total liability for any claim related to the service is limited to the amount you paid us for \(AppBranding.proName) in the twelve (12) months before the claim, or one hundred New Zealand dollars (NZD $100) if you use the free tier.

                Some jurisdictions do not allow certain limitations; in those cases, our liability is limited to the fullest extent permitted by law.
                """
            ),
            LegalSection(
                title: "Termination",
                body: """
                You may stop using the app at any time and delete your account from Profile settings.

                We may suspend or terminate access if you violate these terms or if we discontinue the service. Upon termination, your right to use the app ends, but sections that by nature should survive (such as disclaimers and limitation of liability) will remain in effect.
                """
            ),
            LegalSection(
                title: "Updates to the App and Terms",
                body: """
                We may release updates that add features, fix bugs, or change requirements. Updates may be delivered through the App Store, direct download, or Sparkle (when enabled).

                We may modify these Terms from time to time. The "Last updated" date will change when we do. Continued use after changes constitutes acceptance. If you disagree with updated terms, stop using the app and cancel any active subscription.
                """
            ),
            LegalSection(
                title: "Governing Law",
                body: """
                These Terms are governed by the laws of New Zealand, without regard to conflict-of-law principles. Any disputes will be subject to the exclusive jurisdiction of the courts of New Zealand, except where consumer protection laws in your country require otherwise.
                """
            ),
            LegalSection(
                title: "Contact",
                body: """
                Questions about these Terms? Email \(supportEmail).
                """
            ),
        ]
    }
}
