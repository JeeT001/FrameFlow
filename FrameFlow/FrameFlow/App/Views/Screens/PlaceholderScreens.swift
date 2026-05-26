//
//  PlaceholderScreens.swift
//  FrameFlow
//

import SwiftUI

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

struct SubscriptionView: View {
    var body: some View { ScreenPlaceholder(route: .subscription) }
}

struct PaymentView: View {
    var body: some View { ScreenPlaceholder(route: .payment) }
}

struct ResetPasswordView: View {
    var body: some View { ScreenPlaceholder(route: .resetPassword) }
}
