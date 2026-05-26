//
//  RouteDetailView.swift
//  FrameFlow
//

import SwiftUI

struct RouteDetailView: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .dashboard:
            DashboardView()
        case .windowPicker:
            WindowPickerView()
        case .layoutPicker:
            LayoutPickerView()
        case .audioMode:
            AudioModePickerStandaloneView()
        case .recording:
            RecordingView()
        case .captionEditor:
            CaptionEditorView()
        case .export:
            ExportView()
        case .recordingDetail:
            RecordingDetailView()
        case .profile:
            ProfileView()
        case .settings:
            SettingsView()
        case .subscription:
            SubscriptionView()
        case .payment:
            PaymentView()
        case .help:
            HelpView()
        case .onboarding:
            OnboardingView()
        case .login:
            LoginView()
        case .signUp:
            SignUpView()
        case .forgotPassword:
            ForgotPasswordView()
        case .resetPassword:
            ResetPasswordView()
        }
    }
}

#Preview {
    RouteDetailView(route: .dashboard)
}
