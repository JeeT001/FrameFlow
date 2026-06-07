//
//  Models.swift
//  FrameFlow
//

import Foundation

enum SidebarSection: String, CaseIterable, Identifiable {
    case home
    case settings
    case account

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .settings: "Settings"
        case .account: "Account"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .settings: "gearshape"
        case .account: "person.circle"
        }
    }
}

enum AppRoute: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case windowPicker
    case layoutPicker
    case audioMode
    case recording
    case editor
    case captionEditor
    case export
    case recordingDetail
    case profile
    case settings
    case subscription
    case payment
    case help
    case onboarding
    case login
    case signUp
    case forgotPassword
    case resetPassword

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .windowPicker: "Window Picker"
        case .layoutPicker: "Layout Picker"
        case .audioMode: "Audio Mode"
        case .recording: "Recording"
        case .editor: "Editor"
        case .captionEditor: "Caption Editor"
        case .export: "Export"
        case .recordingDetail: "Recording Detail"
        case .profile: "Profile"
        case .settings: "Settings"
        case .subscription: "Subscription"
        case .payment: "Payment"
        case .help: "Help"
        case .onboarding: "Onboarding"
        case .login: "Login"
        case .signUp: "Sign Up"
        case .forgotPassword: "Forgot Password"
        case .resetPassword: "Reset Password"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "rectangle.stack.badge.plus"
        case .windowPicker: "macwindow.on.rectangle"
        case .layoutPicker: "square.split.2x1"
        case .audioMode: "waveform"
        case .recording: "record.circle"
        case .editor: "film.stack"
        case .captionEditor: "captions.bubble"
        case .export: "square.and.arrow.up"
        case .recordingDetail: "play.rectangle"
        case .profile: "person.circle"
        case .settings: "gearshape"
        case .subscription: "crown"
        case .payment: "creditcard"
        case .help: "questionmark.circle"
        case .onboarding: "hand.wave"
        case .login: "person.badge.key"
        case .signUp: "person.badge.plus"
        case .forgotPassword: "envelope"
        case .resetPassword: "lock.rotation"
        }
    }

    var subtitle: String {
        switch self {
        case .dashboard:
            "Main hub for recent recordings and starting a new capture."
        case .windowPicker:
            "Select which open app windows to include in the recording."
        case .layoutPicker:
            "Choose format, layout, camera, and audio before you record."
        case .audioMode:
            "Choose how microphone and system audio are captured."
        case .recording:
            "Live composite view with recording controls and HUD."
        case .editor:
            "Review, caption, and export your recording in one place."
        case .captionEditor:
            "Legacy caption editor — use Editor for post-record flow."
        case .export:
            "Preview the recording and export at the chosen resolution."
        case .recordingDetail:
            "View, rename, re-export, or delete a saved recording."
        case .profile:
            "Account details, subscription status, and sign out."
        case .settings:
            "Default recording, export, caption, and permission preferences."
        case .subscription:
            "Compare Free vs Pro plans and start a trial."
        case .payment:
            "Complete checkout for the selected subscription plan."
        case .help:
            "FAQs, support contact, and legal links."
        case .onboarding:
            "First-run welcome and three-step product overview."
        case .login:
            "Sign in with email and password."
        case .signUp:
            "Create a new FrameFlow account."
        case .forgotPassword:
            "Request a password reset link by email."
        case .resetPassword:
            "Set a new password from the email reset link."
        }
    }

    var plannedElements: [String] {
        switch self {
        case .onboarding:
            ["App logo", "3-step carousel", "Sign Up", "Log In"]
        case .signUp:
            ["Full name", "Email", "Password", "Confirm password", "Sign Up", "Log In link"]
        case .login:
            ["Email", "Password", "Log In", "Forgot Password", "Sign Up link"]
        case .forgotPassword:
            ["Email", "Send Reset Link", "Back to Login"]
        case .resetPassword:
            ["New password", "Confirm password", "Set New Password"]
        case .dashboard:
            ["User avatar", "Upgrade", "New Recording", "Recent Recordings", "Subscription banner"]
        case .windowPicker:
            ["Window grid", "Selected count", "Next: Choose Layout", "Upgrade banner", "Refresh"]
        case .layoutPicker:
            ["Format toggle", "Layout presets", "Live preview", "Camera toggle", "Audio mode", "Auto-Focus", "Cursor Highlight", "Countdown", "Start Recording"]
        case .audioMode:
            ["Microphone Only", "System Audio Only", "Mic + System", "No Audio", "Volume sliders", "Confirm"]
        case .recording:
            ["Live canvas", "Camera PiP", "Auto-focus highlight", "Cursor highlight", "Recording HUD", "Countdown overlay"]
        case .editor:
            ["Video preview", "Edit tab", "Captions tab (Pro)", "Export tab", "Toolbar Export", "Discard"]
        case .captionEditor:
            ["Video player", "Caption segments", "Style presets", "Caption position", "Export format", "Export", "Skip Captions"]
        case .export:
            ["Video player", "Duration & size", "Resolution picker", "Export", "Save to Folder", "Discard"]
        case .recordingDetail:
            ["Thumbnail", "File name", "Play", "Re-export", "Delete"]
        case .profile:
            ["Avatar", "Display name", "Email", "Subscription badge", "Manage Subscription", "Change Password", "Log Out"]
        case .settings:
            ["Export resolution", "Save folder", "Audio defaults", "Permission status", "Dark mode", "Check for Updates"]
        case .subscription:
            ["Feature comparison", "Annual plan", "Monthly plan", "Lifetime plan", "Start Free Trial", "Restore Purchase"]
        case .payment:
            ["Order summary", "Payment sheet", "Pay"]
        case .help:
            ["FAQ list", "Email Support", "Privacy Policy", "Terms of Service", "App version"]
        }
    }

    static func route(for section: SidebarSection) -> AppRoute {
        switch section {
        case .home: .dashboard
        case .settings: .settings
        case .account: .profile
        }
    }
}
