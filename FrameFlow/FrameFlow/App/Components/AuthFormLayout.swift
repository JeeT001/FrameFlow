//
//  AuthFormLayout.swift
//  FrameFlow
//

import SwiftUI

struct AuthFormLayout<Content: View, Footer: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.footer = footer
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.semibold)

                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                }

                VStack(alignment: .leading, spacing: 16) {
                    content()
                }
                .frame(maxWidth: 380)

                footer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        }
        .navigationTitle(title)
    }
}

struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(AppColors.recRed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(AppColors.recRed.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct AuthSuccessBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(AppColors.successGreen)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(AppColors.successGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}
