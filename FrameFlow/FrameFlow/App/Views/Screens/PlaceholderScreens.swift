//
//  PlaceholderScreens.swift
//  FrameFlow
//

import SwiftUI

struct DashboardView: View {
    var body: some View { ScreenPlaceholder(route: .dashboard) }
}

struct WindowPickerView: View {
    var body: some View { ScreenPlaceholder(route: .windowPicker) }
}

struct LayoutPickerView: View {
    var body: some View { ScreenPlaceholder(route: .layoutPicker) }
}

struct AudioModePickerView: View {
    var body: some View { ScreenPlaceholder(route: .audioMode) }
}

struct RecordingView: View {
    var body: some View { ScreenPlaceholder(route: .recording) }
}

struct CaptionEditorView: View {
    var body: some View { ScreenPlaceholder(route: .captionEditor) }
}

struct ExportView: View {
    var body: some View { ScreenPlaceholder(route: .export) }
}

struct RecordingDetailView: View {
    var body: some View { ScreenPlaceholder(route: .recordingDetail) }
}

struct ProfileView: View {
    var body: some View { ScreenPlaceholder(route: .profile) }
}

struct SettingsView: View {
    var body: some View { ScreenPlaceholder(route: .settings) }
}

struct SubscriptionView: View {
    var body: some View { ScreenPlaceholder(route: .subscription) }
}

struct PaymentView: View {
    var body: some View { ScreenPlaceholder(route: .payment) }
}

struct HelpView: View {
    var body: some View { ScreenPlaceholder(route: .help) }
}

struct OnboardingView: View {
    var body: some View { ScreenPlaceholder(route: .onboarding) }
}

struct ResetPasswordView: View {
    var body: some View { ScreenPlaceholder(route: .resetPassword) }
}
